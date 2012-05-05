function! s:get_fb_client() "{{{
    if !exists("s:fb_client")
        let s:fb_client = facebook#client#get_instance()
    endif

    return s:fb_client
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

    call facebook#home#open(res)
    call s:define_home_keymap()
endfunction

function! facebook#wallpost()
    call facebook#post#open('Wall')
    call s:define_post_keymap()    
endfunction

function! facebook#authenticate()
    call s:get_fb_client().authenticate()
endfunction

" vim: foldmethod=marker
