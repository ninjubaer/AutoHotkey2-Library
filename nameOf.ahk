nameOf(&obj) => StrGet(NumGet(ObjPtr(&obj) + 8 + 6 * A_PtrSize, 'ptr')) ; by thqby