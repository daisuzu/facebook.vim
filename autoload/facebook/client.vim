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
    let param = {'access_token': s:fb_client.access_token}
    if len(a:content)
        let param['message'] = a:content
    endif

    let res = webapi#http#post("https://graph.facebook.com" . a:path, param)

    if res.header[0] =~ 'HTTP/1.1 400'
        throw "AuthenticationError"
    endif

endfunction "}}}

function! s:fb_client.delete(path) "{{{
    echomsg "Not Implemented."
endfunction "}}}

function! s:fb_client.authenticate() "{{{
    let s:fb_client.access_token = s:get_access_token()
endfunction "}}}
"}}}

function! s:get_access_token() "{{{
    let needs_auth = 1
    if filereadable(g:facebook_access_token_file)
        let data = webapi#json#decode(readfile(g:facebook_access_token_file)[0])
        if has_key(data, 'expires_at') && localtime() < data['expires_at']
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

function! facebook#client#get_instance()
    if !exists("s:fb_client.access_token") || len(s:fb_client.access_token) < 1
        let s:fb_client.access_token = s:get_access_token()
    endif

    return s:fb_client
endfunction

" vim: foldmethod=marker
