let s:V = vital#of('facebook.vim')
let s:BufferManager = s:V.import('Vim.BufferManager')
let s:DateTime = s:V.import('DateTime')

let s:home_buffer = s:BufferManager.new()
let s:feed_buffer = s:BufferManager.new()
let s:info_buffer = s:BufferManager.new()
let s:post_buffer = s:BufferManager.new()

function! s:get_fb_client() "{{{
    if !exists("s:fb_client")
        let s:fb_client = facebook#client#get_instance()
    endif

    return s:fb_client
endfunction "}}}

function! s:open_link(line) "{{{
    let url = a:line

    if url !~ 'http[s]*://'
        call search('^\[.*http[s]*://', 'b')
        let url = getline('.')
    endif

    let link_start_pos = match(url, 'http[s]*://')
    if link_start_pos > -1
        call openbrowser#open(url[link_start_pos : ])
    endif
endfunction "}}}

function! s:publishing_or_open(line) "{{{
    if a:line =~ '^comments:'
        call s:post_buffer.open('[Facebook Post - ' . s:get_object_id_from_buffer() . ']', {'opener': 'botright split'})
        call s:define_post_keymap()
    elseif a:line =~ '^like:'
        let object_id = s:get_object_id_from_buffer()
        if len(object_id)
            let dst = '/' . object_id . '/likes'
            try
                let res = s:get_fb_client().post(dst, '')
                echomsg "Succeed to Like!"
            catch "AuthenticationError"
                echomsg "Authentication Error"
            endtry
        endif
    else
        call s:open_link(a:line)
    endif
endfunction "}}}

function! s:get_contents_info(line) "{{{
    if a:line =~ '^comments:'
        let object_id = '/' . s:get_object_id_from_buffer() . '/comments'
    elseif a:line =~ '^like:'
        let object_id = '/' . s:get_object_id_from_buffer() . '/likes'
    else
        return
    endif

    try
        let res = s:get_fb_client().get(object_id)
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call s:info_buffer.open('[Facebook Info]', {'opener': 'vertical topleft split'})
    call s:show_info(res)
endfunction "}}}

function! s:define_home_feed_keymap() "{{{
    nnoremap <buffer> <silent> <CR> :<C-u>call <SID>open_link(getline('.'))<CR>
    nnoremap <buffer> <silent> <S-CR> :<C-u>call <SID>publishing_or_open(getline('.'))<CR>
    nnoremap <buffer> <silent> <Tab> :<C-u>call <SID>get_contents_info(getline('.'))<CR>
endfunction "}}}

function! s:define_post_keymap() "{{{
    nnoremap <buffer> <silent> q :<C-u>call <SID>do_post()<CR>
endfunction "}}}

function! s:do_post() "{{{
    let post_buf = getline(1, '$')
    if post_buf == ['']
        echomsg "Post data is empty!"
        bdelete!
        return
    endif

    let content = iconv(join(post_buf, "\n")."\n", &encoding, "utf-8")
    let dst = s:get_dst_from_bufname()

    if len(dst)
        try
            let res = s:get_fb_client().post(dst, content)
            bdelete!
            echomsg "Succeed to Post!"
        catch "AuthenticationError"
            echomsg "Authentication Error"
        endtry
    endif
endfunction "}}}

function! s:get_dst_from_bufname() "{{{
    let buf_name = bufname(bufnr('%'))
    if buf_name =~ 'Post - Wall'
        return '/me/feed'
    else
        let object_id = split(buf_name, ' - ')[1][:-2]
        return '/' . object_id . '/comments'
    endif
endfunction "}}}

function! s:get_object_id_from_buffer() "{{{
    call search('^\[.*http[s]*://', 'b')
    let url = getline('.')

    return join(matchlist(url, '\(\d*\)/posts/\(\d*\)')[1:2], '_')
endfunction "}}}

function! s:local_time(str) "{{{
    return s:DateTime.from_date(
                \ a:str[:3],
                \ a:str[5:6],
                \ a:str[8:9],
                \ a:str[11:12],
                \ a:str[14:15],
                \ a:str[17:18],
                \ a:str[19:]
                \ ).to(g:facebook_timezone).to_string()
endfunctio "}}}

function! s:show_data(res) "{{{
    for v in a:res['data']
        if has_key(v, 'actions')
            let contents_url = v['actions'][0]['link']
        else
            let content_id = split(v['id'], '_')
            let contents_url = 'http://www.facebook.com/' . content_id[0] . '/posts/' . content_id[1]
        endif

        call append(line('$'), '[' .s:local_time(v['created_time']) . '] ' . v['from']['name'] . ' ' . contents_url)
        if has_key(v, 'message')
            call append(line('$'), map(split(v['message'], '\n'), '"  ".v:val'))
        endif
        if has_key(v, 'name')
            call append(line('$'), 'name:' . v['name'])
        endif
        if has_key(v, 'description')
            call append(line('$'), 'description:' . v['description'])
        endif
        if has_key(v, 'story')
            call append(line('$'), 'story:' . v['story'])
        endif
        if has_key(v, 'place')
            call append(line('$'), 'place:' . v['place']['name'])
        endif
        if has_key(v, 'link')
            call append(line('$'), 'link:' . v['link'])
        endif
        if has_key(v, 'comments')
            call append(line('$'), 'comments:' . len(v['comments']['data']))
        else
            call append(line('$'), 'comments:' . '0')
        endif
        if has_key(v, 'likes')
            call append(line('$'), 'like:' . len(v['likes']['data']))
        else
            call append(line('$'), 'like:' . '0')
        endif
        call append(line('$'), '')
    endfor

    1 delete _
    setlocal nomodified
    setlocal syntax=facebook
endfunction "}}}

function! s:show_info(res) "{{{
    for v in a:res['data']
        if has_key(v, 'message')
            call append(line('$'), '[' .s:local_time(v['created_time']) . '] ' . v['from']['name'] . 'http://')
            call append(line('$'), map(split(v['message'], '\n'), '"  ".v:val'))
        endif
        if has_key(v, 'name')
            call append(line('$'), 'name:' . v['name'])
        endif
        call append(line('$'), '')
    endfor

    1 delete _
    setlocal nomodified
    setlocal syntax=facebook
endfunction "}}}

function! facebook#home()
    echomsg "/me/home is deprecated"
    try
        let res = s:get_fb_client().get('/me/home')
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call s:home_buffer.open('[Facebook Home]', {'opener': 'tabnew'})
    call s:show_data(res)
    call s:define_home_feed_keymap()
endfunction

function! facebook#feed()
    try
        let res = s:get_fb_client().get('/me/feed')
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call s:feed_buffer.open('[Facebook Feed]', {'opener': 'tabnew'})
    call s:show_data(res)
    call s:define_home_feed_keymap()
endfunction

function! facebook#wallpost()
    call s:post_buffer.open('[Facebook Post - Wall]', {'opener': 'botright split'})
    call s:define_post_keymap()
endfunction

function! facebook#authenticate()
    call s:get_fb_client().authenticate()
endfunction

" vim: foldmethod=marker
