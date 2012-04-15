let s:V = vital#of('facebook')
let s:DateTime = s:V.import('DateTime')

let s:fb_client = {} "{{{

function! s:fb_client.get_url(path) "{{{
    return 'https://graph.facebook.com' . a:path . '?' . webapi#http#encodeURI({'access_token': s:fb_client.access_token})
endfunction "}}}

function! s:fb_client.get(path) "{{{
    let res = webapi#http#get(s:fb_client.get_url(a:path))

    if res.header[0] =~ 'HTTP/1.1 400'
        throw "AuthenticationError"
    endif

    return webapi#json#decode(res.content)
endfunction "}}}

function! s:fb_client.post(path, content) "{{{

    let res = webapi#http#post("https://graph.facebook.com" . a:path, {'access_token': s:fb_client.access_token, 'message': a:content})

    if res.header[0] =~ 'HTTP/1.1 400'
        throw "AuthenticationError"
    endif

endfunction "}}}

function! s:fb_client.delete(path) "{{{
    echomsg "Not Implemented."
endfunction "}}}

function! s:get_fb_client() "{{{
    if !exists("s:fb_client.access_token") || len(s:fb_client.access_token) < 1
        let s:fb_client.access_token = s:get_access_token()
    endif

    return s:fb_client
endfunction "}}}
"}}}

function! s:get_access_token() "{{{
    let needs_auth = 1
    if filereadable(g:facebook_access_token_file)
        let data = webapi#json#decode(readfile(g:facebook_access_token_file)[0])
        if localtime() < data['expires_at']
            let needs_auth = 0
        endif
    endif

    if needs_auth
        let auth_script = globpath(&rtp, 'fb_auth.py')
        if &shell =~# 'cmd'
            let auth_cmd = join([auth_script, g:facebook_access_token_file], '" "')
            let auth_cmd = substitute(auth_cmd, '/', '\\', 'g') 
            call system('cmd /c python "' . auth_cmd . '"')
        else
            let auth_cmd = join([auth_script, g:facebook_access_token_file])
            call system(' (python ' . auth_cmd . ') ')
        endif
        let data = webapi#json#decode(readfile(g:facebook_access_token_file)[0])
    endif

    return data["access_token"]
endfunction "}}}

function! s:open_link(url) "{{{
    let url = a:url

    if url !~ 'http[s]*://'
        call search('^\[.*http[s]*://', 'b')
        let url = getline('.')
    endif

    let link_start_pos = match(url, 'http[s]*://')
    if link_start_pos > -1
        call openbrowser#open(url[link_start_pos : ])
    endif
endfunction "}}}

function! s:define_home_keymap() "{{{
    nnoremap <buffer> <silent> <CR> :<C-u>call <SID>open_link(getline('.'))<CR>
endfunction "}}}

function! s:define_post_keymap() "{{{
    nnoremap <buffer> <silent> q :<C-u>call <SID>do_post()<CR>
endfunction "}}}

function! s:tz_time_from_str(str) "{{{
    return s:DateTime.from_date(
                \ a:str[:3],
                \ a:str[5:6],
                \ a:str[8:9],
                \ a:str[11:12],
                \ a:str[14:15],
                \ a:str[17:18],
                \ a:str[19:]
                \ ).timezone(g:facebook_timezone).to_string()
endfunctio "}}}

function! s:open_facebook_home_window() "{{{
    if !exists('s:bufnr_home')
        let s:bufnr_home = -1
    endif
    if !bufexists(s:bufnr_home)
        execute 'tabnew'
        edit `='[Facebook]'`
        let s:bufnr_home = bufnr('%')
    else
        let fb_tabpage = 0
        for i in range(tabpagenr('$'))
            let tablist = tabpagebuflist(i + 1)
            if count(tablist, s:bufnr_home)
                let fb_tabpage = i + 1
                break
            endif
        endfor

        if fb_tabpage
            execute 'tabnext' fb_tabpage
            execute bufwinnr(s:bufnr_home) 'wincmd w'
        else
            execute 'tabnew'
            execute 'buffer' s:bufnr_home
        endif
    endif

    % delete _

    call s:define_home_keymap()
endfunction "}}}

function! s:open_facebook_post_window() "{{{
    if !exists('s:bufnr_post')
        let s:bufnr_post = -1
    endif
    if !bufexists(s:bufnr_post)
        execute 'botright split'
        edit `='[Facebook Post - Wall]'`
        let s:bufnr_post = bufnr('%')
    elseif bufwinnr(s:bufnr_post) != -1
        execute bufwinnr(s:bufnr_post) 'wincmd w'
    else
        execute 'botright split'
        execute 'buffer' s:bufnr_post
    endif

    % delete _

    call s:define_post_keymap()    
endfunction "}}}

function s:do_post() "{{{
    let post_buf = getline(1, '$')
    if post_buf == ['']
        echomsg "Post data is empty!"
        return
    endif

    let content = iconv(join(post_buf, "\n")."\n", &encoding, "utf-8")
    let url = s:get_buf_url()

    if len(url)
        try
            let res = s:get_fb_client().post(url, content)
            bdelete!
            echomsg "Succeed to Post!"
        catch "AuthenticationError"
            echomsg "Authentication Error"
        endtry
    endif
endfunction "}}}

function! s:get_buf_url() "{{{
    let buf_name = bufname(bufnr('%'))
    if buf_name =~ 'Post - Wall'
        return '/me/feed'
    else
        " TODO Not implemented
        return ''
    endif
endfunction "}}}

function! facebook#home()
    try
        let res = s:get_fb_client().get('/me/home')
    catch "AuthenticationError"
        echomsg "Authentication Error"
        return
    endtry

    call s:open_facebook_home_window()

    for v in res['data']
        if has_key(v, 'actions')
            let contents_url = v['actions'][0]['link']
        else
            let content_id = split(v['id'], '_')
            let contents_url = 'http://www.facebook.com/' . content_id[0] . '/posts/' . content_id[1] 
        endif
        call append(line('$'), '[' .s:tz_time_from_str(v['created_time']) . '] ' . v['from']['name'] . ' ' . contents_url)
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
            call append(line('$'), 'comments:' . v['comments']['count'])
        endif
        if has_key(v, 'likes')
            call append(line('$'), 'like:' . v['likes']['count'])
        else
            call append(line('$'), 'like:' . '0')
        endif
        call append(line('$'), '')
    endfor

    1 delete _
    setlocal nomodified
    setlocal syntax=facebook

endfunction

function! facebook#wallpost()
    call s:open_facebook_post_window()
endfunction

function! facebook#authenticate()
    let s:fb_client.access_token = s:get_access_token()
endfunction

" vim: foldmethod=marker
