/************************************************************************
 * @description Class for 2D arrays in AutoHotkey
 * @file Array2D.ahk
 * @author ninju
 * @date 2024/05/23
 * @version 0.0.1
 ***********************************************************************/

class Array2D extends Array {
    __new(x, y, fill?) {
        row := []
        loop x
            row.Push(fill ?? 0)
        this.arr := []
        loop y
            this.arr.Push(row.clone())
    }
    __item[x, y] {
        get => this.arr[y+1][x+1]
        set => this.arr[y+1][x+1] := value
    }
}