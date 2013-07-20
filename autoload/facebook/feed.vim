let s:V = vital#of('facebook')
let s:DateTime = s:V.import('DateTime')

function! s:open_buffer() "{{{
    if !exists('s:bufnr_feed')
        let s:bufnr_feed = -1
    endif
    if !bufexists(s:bufnr_feed)
        execute 'tabnew'
        edit `='[Facebook Feed]'`
        let s:bufnr_feed = bufnr('%')
    else
        let fb_tabpage = 0
        for i in range(tabpagenr('$'))
            let tablist = tabpagebuflist(i + 1)
            if count(tablist, s:bufnr_feed)
                let fb_tabpage = i + 1
                break
            endif
        endfor

        if fb_tabpage
            execute 'tabnext' fb_tabpage
            execute bufwinnr(s:bufnr_feed) 'wincmd w'
        else
            execute 'tabnew'
            execute 'buffer' s:bufnr_feed
        endif
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
endfunction "}}}

function! facebook#feed#open(res)
    call s:open_buffer()
    call s:show_data(a:res)
endfunction

" vim: foldmethod=marker
