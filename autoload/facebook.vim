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
        call facebook#post#open(s:get_object_id_from_buffer())
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

function! s:define_home_feed_keymap() "{{{
    nnoremap <buffer> <silent> <CR> :<C-u>call <SID>open_link(getline('.'))<CR>
    nnoremap <buffer> <silent> <S-CR> :<C-u>call <SID>publishing_or_open(getline('.'))<CR>
endfunction "}}}

function! s:define_post_keymap() "{{{
    nnoremap <buffer> <silent> q :<C-u>call <SID>do_post()<CR>
endfunction "}}}

function! s:do_post() "{{{
    let post_buf = getline(1, '$')
    if post_buf == ['']
        echomsg "Post data is empty!"
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

function! facebook#home()
    try
        let res = s:get_fb_client().get('/me/home')
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call facebook#home#open(res)
    call s:define_home_feed_keymap()
endfunction

function! facebook#feed()
    try
        let res = s:get_fb_client().get('/me/feed')
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call facebook#feed#open(res)
    call s:define_home_feed_keymap()
endfunction

function! facebook#wallpost()
    call facebook#post#open('Wall')
    call s:define_post_keymap()    
endfunction

function! facebook#authenticate()
    call s:get_fb_client().authenticate()
endfunction

" vim: foldmethod=marker
