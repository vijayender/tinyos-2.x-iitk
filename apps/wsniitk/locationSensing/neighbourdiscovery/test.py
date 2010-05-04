import select, sys
i = 0
while True:
    i+=1
    if isData():
        print i, 'You typed:', sys.stdin.readline()
    else:
        print i, '.'
