let s:V = vital#of('facebook')
let s:DateTime = s:V.import('DateTime')

function! s:open_buffer() "{{{
    if !exists('s:bufnr_info')
        let s:bufnr_info = -1
    endif
    if !bufexists(s:bufnr_info)
        execute 'vertical topleft split'
        edit `='[Facebook Info]'`
        let s:bufnr_info = bufnr('%')
    elseif bufwinnr(s:bufnr_info) != -1
        execute bufwinnr(s:bufnr_info) 'wincmd w'
    else
        execute 'vertical topleft split'
        execute 'buffer' s:bufnr_info
    endif

    % delete _
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
                \ ).timezone(g:facebook_timezone).to_string()
endfunctio "}}}

function! s:show_data(res) "{{{
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

function! facebook#info#open(res)
    call s:open_buffer()
    call s:show_data(a:res)
endfunction

" vim: foldmethod=marker
