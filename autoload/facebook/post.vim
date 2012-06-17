function! s:open_buffer(dst) "{{{
    if !exists('s:bufnr_post')
        let s:bufnr_post = -1
    endif
    if !bufexists(s:bufnr_post)
        execute 'botright split'
        edit `='[Facebook Post - ' . a:dst . ']'`
        let s:bufnr_post = bufnr('%')
    elseif bufwinnr(s:bufnr_post) != -1
        execute bufwinnr(s:bufnr_post) 'wincmd w'
    else
        execute 'botright split'
        execute 'buffer' s:bufnr_post
    endif

    % delete _
endfunction "}}}

function! facebook#post#open(dst)
    call s:open_buffer(a:dst)
endfunction

function! facebook#post#close()
    unlet s:bufnr_post
    bdelete!
endfunction

" vim: foldmethod=marker
