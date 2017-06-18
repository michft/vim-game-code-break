let s:config = {
            \ 'width': 0,
            \ 'height': 0,
            \ 'empty_line': '',
            \}
let s:data = {
            \ 'text': '',
            \ 'temp': '',
            \}
let s:ship = {
            \'center' : { 'x': 0, 'y': 0 },
            \'left' : '',
            \'body' : 'XXXXXXXXXXXXXXXXX',
            \'direction' : 'left',
            \'location': 0,
            \}
let s:ball_proto = { 'x': 0, 'y': 0, 'active': 0 }

let s:move = {
            \ 'left-up'    : { 'x' : -1, 'y' : -1 },
            \ 'left-down'  : { 'x' : -1, 'y' :  1 },
            \ 'right-up'   : { 'x' : 1 , 'y' : -1 },
            \ 'right-down' : { 'x' : 1 , 'y' :  1 },
            \ 'up'         : { 'x' : 0 , 'y' : -1 },
            \ 'down'       : { 'x' : 0 , 'y' :  1 },
            \ }

let s:ball = {'x': -1, 'y':-1, 'direction': s:move['left-up']}

function! VimGameCodeBreak#game#main()

    let s:data['temp'] = getreg('z')
    execute "normal! ggVG\"zy"
    let s:data['text'] = getreg('z')

    call s:init()

    execute "normal! Gzb"

    let l:loop = 1
    while l:loop == 1
        let l:input = nr2char(getchar(0))
        call s:userInputProc(l:input)
        call s:updateItems()
        sleep 30ms
        redraw
    endwhile

endfunction

function! s:userInputProc(input)
    if a:input == 'h'
        let s:ship['direction'] = 'left'
    elseif a:input == 'l'
        let s:ship['direction'] = 'right'
    elseif a:input == ' '
        call s:createNewBall()
    endif
endfunction

function! s:createNewBall()
    let l:y = line('$') - 1
    let l:x = s:ship['center']['x']
    let s:ball['x'] = l:x
    let s:ball['y'] = l:y
endfunction

function! s:updateItems()
    if (s:ship['direction'] == 'left')
        call s:moveShipLeft()
    elseif (s:ship['direction'] == 'right')
        call s:moveShipRight()
    endif
    call s:moveBall()
endfunction

function! s:moveBall()

    if s:ball['x'] == -1 || s:ball['y'] == -1
        return
    endif

    let l:x = s:ball['x']
    let l:y = s:ball['y']
    call s:drawChar(l:x, l:y, ' ')

    if s:pongX(l:x, l:y) == 1
        let s:ball['direction']['y'] = -1 * (s:ball['direction']['y'])
    endif

    if s:pongY(l:x, l:y) == 1
        let s:ball['direction']['x'] = -1 * (s:ball['direction']['x'])
    endif

    let s:ball['x'] = l:x + s:ball['direction']['x']
    let s:ball['y'] = l:y + s:ball['direction']['y']

    call s:drawChar(s:ball['x'], s:ball['y'], 'O')

endfunction

" ball 의 X axis 충돌 처리를 한다
function! s:pongX(x, y)

    let l:last = line('$')
    let l:yy = a:y + s:ball['direction']['y']

    if l:yy >= l:last
        " 바닥에 닿은 경우
        " call s:removeEmptyLines()
        return 1
    endif

    if a:y <= (l:last - s:config['height'])
        " 천장에 닿은 경우
        return 1
    endif

    if s:getCharValue(a:x, l:yy) != ' '
        " 글자에 닿은 경우
        if l:yy < line('$')
            execute "normal! " . l:yy . "gg0" . a:x . "lviWr G0"
        endif
        return 1
    endif

    return 0
endfunction

" ball 의 Y axis 충돌 처리를 한다
function! s:pongY(x, y)

    let l:xx = a:x + s:ball['direction']['x']
    let l:last = s:config['width']

    if ((l:xx <= 0) || (a:x >= l:last)) && (a:y - 1 >= 1)
        " 좌우 벽에 닿은 경우: line join
        let l:row = substitute(getline(a:y - 1), '\s*$', ' ', '')
        call setline(a:y - 1, l:row)
        execute "" . (a:y - 1) . "j"
        let l:botrow = substitute(getline(a:y - 1), '$', s:config['empty_line'], '')
        call setline(a:y - 1, l:botrow)
        execute "normal! G0zb"
        return 1
    endif

    if s:getCharValue(l:xx, a:y) != ' '
        " 글자에 닿은 경우
        execute "normal! " . a:y . "gg0" . l:xx . "lviWr G0zb"
        return 1
    endif

    if a:x >= l:last
        return 1
    endif
    return 0
endfunction

function! s:getCharValue(x, y)
    return getline(a:y)[a:x]
endfunction

function! s:moveShipLeft()
    setlocal statusline=%!VimGameCodeBreak#game#showShip(-1)
endfunction

function! s:moveShipRight()
    setlocal statusline=%!VimGameCodeBreak#game#showShip(1)
endfunction

" game initialize
function! s:init()
    let l:file_name = expand('%:t')
    call s:createBuffer(l:file_name)
    call s:setLocalSetting()
    call s:setConfig()
    call s:setColor()
    call s:drawScreen()
    call s:drawShip()
    execute "normal! Gzb"
endfunction

function! s:createBuffer(filename)
    silent edit `='VIM-GAME-CODE-BREAK-' . a:filename`
    execute "normal! \"zp"
    call setreg('z', s:data['temp'])
endfunction

function! s:setLocalSetting()
    setlocal bufhidden=wipe
    setlocal buftype=nofile
    setlocal buftype=nowrite
    setlocal nocursorcolumn
    setlocal nocursorline
    setlocal nolist
    setlocal nonumber
    setlocal noswapfile
    setlocal nowrap
    setlocal nohlsearch
    " setlocal nonumber
    setlocal norelativenumber
    setlocal listchars=
    setlocal laststatus=2
    setlocal statusline=%!VimGameCodeBreak#game#showShip()
    hi statusLine ctermfg=yellow ctermbg=NONE guifg=yellow guibg=NONE
    retab
endfunction

function! VimGameCodeBreak#game#showShip(move)
    if a:move > 0 && (strlen(s:ship['body']) + strlen(s:ship['left'])) < s:config['width']
        " let s:sleft = " " . s:sleft
        let s:ship['left'] = " " . s:ship['left']
    elseif a:move < 0 && s:ship['left'][0] == " "
        let s:ship['left'] = s:ship['left'][1:]
    endif
    return s:ship['left'] . s:ship['body']
endfunction

"
function! s:setColor()
    " syntax region gameship start="\v\<12" end="\v21\>"
    " highlight gameship ctermfg=yellow ctermbg=yellow guifg=yellow guibg=yellow
endfunction

function! s:drawScreen()
    execute "normal! Go"
    let l:width = s:config['width']
    let l:last_line = line('$')

    let l:bottom_lines = repeat([repeat(' ', l:width)], 5)
    call setline(l:last_line, l:bottom_lines)

    call s:appendChars()
    call s:removeEmptyLines()

    execute "normal! ggO"
    execute "normal! S"
    execute "normal! yy" . s:config['height'] . "pGzb"
endfunction

function! s:removeEmptyLines()
    silent! 0,$-10g/^\s*$/d
endfunction

function! s:appendChars()
    let l:chars = s:config['empty_line']
    silent! %s/$/\=l:chars/
endfunction

function! s:drawShip()
    execute "normal! Go"
endfunction

function! s:setConfig()
    let s:config['width'] = winwidth(0)
    let s:config['height'] = winheight(0)

    let l:width = s:config['width']
    let l:chars = ''

    for cnt in range(1, l:width)
        let l:chars = l:chars . ' '
    endfor

    let s:config['empty_line'] = l:chars
endfunction

function! s:drawChar(x, y, char)
    let l:row = getline(a:y)
    let l:newRow = l:row[0:(a:x - 1)] . a:char . l:row[(a:x + 1):]
    call setline(a:y, l:newRow)
endfunction