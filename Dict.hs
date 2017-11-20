module Dict where

import FTypes
import DSP

-- helper functions
stack_op :: (FDataStack -> FDataStack) -> FState -> FState
stack_op f s = s { datastack = f (datastack s) }

stack_pop :: FDataStack -> FDataStack
stack_pop = drop 1

output_append :: FOutput -> FState -> FState
output_append str s = s { output_string = (output_string s) ++ str }

-- DICTIONARY

-- to be fixed / changed
-- WORD must discard leading whitespace

-- to be added
-- FORGET (forgets all words defined since the named word)
-- ." (prints until it encounters ")
-- CR (prints a carriage return)
-- SPACE (prints a space)
-- SPACES (prints n spaces)
-- MOD (n1 n2 -- rem)
-- /MOD (n1 n2 -- rem quot)
-- INCLUDE (loads & interprets a text file from disk)
-- = < > 0= 0< 0>
-- IF ELSE THEN
-- INVERT (inverts a flag)
-- ?DUP (dupes top stack value only if it's a TRUE flag)
-- ABORT" (if flag true, clear stack, print name of last interp'd word)
-- ?STACK (true if stack is EMPTY)
--
-- 1+
-- 1-
-- 2+
-- 2-
-- 2* (left shift)
-- 2/ (right shift)
--
-- ABS
-- NEGATE
-- >R and R> (move from stack to rstack then back)
-- */ (multiplies then divides. for fractions)

-- map of native functions
-- must manually add new native words here :/

native_dict = [ (".S"       ,Not  ,FFn  fDOTESS   )
              , ("."        ,Not  ,FFn  fDOT      )
              , ("BL"       ,Not  ,FFn  fBL       )
              , ("WORD"     ,Not  ,FFn  fWORD     )
              , ("FIND"     ,Not  ,FFn  fFIND     )
              , ("["        ,Imm  ,FFn  fLEFTBRAK )
              , ("]"        ,Not  ,FFn  fRITEBRAK )
              , ("("        ,Imm  ,FFn  fPAREN    )
              , (":"        ,Not  ,FCFn fCOLON    )
              , (";"        ,Imm  ,FCFn fSEMIC    )
              , ("IMMEDIATE",Not  ,FFn  fIMMEDIATE)
              , ("BL"       ,Not  ,FFn  fBL       )
              , ("WORD"     ,Not  ,FFn  fWORD     )
              , ("CREATE"   ,Not  ,FFn  fCREATE   )
              , ("DROP"     ,Not  ,FFn  fDROP     )
              , ("*"        ,Not  ,FFn  fSTAR     )
              , ("+"        ,Not  ,FFn  fADD      )
              , ("-"        ,Not  ,FFn  fSUB      )
              , ("/"        ,Not  ,FFn  fDIV      )
              , ("MAX"      ,Not  ,FFn  fMAX      )
              , ("MIN"      ,Not  ,FFn  fMIN      )
              , ("DUP"      ,Not  ,FFn  fDUP      )
              , ("SWAP"     ,Not  ,FFn  fSWAP     )
              , ("ROT"      ,Not  ,FFn  fROT      )
              , ("BYE"      ,Not  ,FFn  fCOLONQ   )
              , (".s"       ,Not  ,FFn  mDOTESS   ) -- specifics for dsp ctrl
              , ("new"      ,Not  ,FFn  mNEW      )
              , ("ins"      ,Not  ,FFn  mINS      )
              , ("outs"     ,Not  ,FFn  mOUTS     )
              , ("pars"     ,Not  ,FFn  mPARS     )
              , ("list"     ,Not  ,FFn  mLIST     )
              , ("con"      ,Not  ,FFn  mCON      )
              , ("dis"      ,Not  ,FFn  mDIS      )
              , ("get"      ,Not  ,FFn  mGET      )
              , ("set"      ,Not  ,FFn  mSET      )
              ]

-- initial dsp-graph-words
mDOTESS :: FState -> FState
mDOTESS = fDOT . stack_op( (FNum 666) : ) --fake data

mNEW :: FState -> FState
mNEW = output_append("takes mod-type. returns id\n")

mINS :: FState -> FState
mINS = output_append("takes mod id. lists inputs\n")

mOUTS :: FState -> FState
mOUTS = output_append("takes mod id. lists outputs\n")

mPARS :: FState -> FState
mPARS = output_append("takes mod id. lists params\n")

mLIST :: FState -> FState
mLIST = output_append("takes mod id. lists ins, outs, params\n")

mCON :: FState -> FState
mCON = output_append("adds patch between 2 endpoints. lists patch id\n")

mDIS :: FState -> FState
mDIS = output_append("takes patch id. returns ok\n")

mGET :: FState -> FState
mGET = output_append("takes mod.par. returns vel\n")

mSET :: FState -> FState
mSET = output_append("takes mod.par & val. retursn ok\n")


-- force quit
fCOLONQ :: FState -> FState
fCOLONQ s = s { quit_flag = True }

-- printing
fDOTESS :: FState -> FState
fDOTESS s@(FState {datastack=[]}) = output_append("stack's empty mate\n") s
fDOTESS s = output_append(  "<len: "
                         ++ (show $ length (datastack s))
                         ++ "> "
                         ++ (show (datastack s))
                         ++ " {"
                         ++ (show (compile_flag s))
                         ++ "} nice stack =]\n"
                         ) s

fDOT :: FState -> FState
fDOT s@(FState {datastack=[]}) = output_append("stack's empty mate\n") s
fDOT s = fDROP . output_append(getPancake(datastack s)) $ s
         where
            getPancake :: FDataStack -> String
            getPancake (cake:cakes) = show(cake) ++ " pancake!\n"

fDOTG :: FState -> FState
fDOTG = output_append( "call to c and print the whole graph!\n" )



-- constants
fBL :: FState -> FState
fBL = stack_op(FStr " " :)



-- arithmetic
fSTAR :: FState -> FState
fSTAR = stack_op(dStar)
    where dStar (FNum s: FNum st:stk) = FNum(s * st) : stk

fADD :: FState -> FState
fADD = stack_op(dAdd)
    where dAdd (FNum s: FNum st:stk) = FNum(s + st) : stk

fSUB :: FState -> FState
fSUB = stack_op(dSub)
    where dSub (FNum s: FNum st:stk) = FNum(s - st) : stk

fDIV :: FState -> FState
fDIV = stack_op(dDiv)
    where dDiv (FNum s: FNum st:stk) = FNum(div s st) : stk

fMAX :: FState -> FState
fMAX = stack_op(dMax)
    where dMax (FNum s: FNum st:stk) = FNum(max s st) : stk

fMIN :: FState -> FState
fMIN = stack_op(dMin)
    where dMin (FNum s: FNum st:stk) = FNum(min s st) : stk



-- stack ops
fDUP :: FState -> FState
fDUP = stack_op(dDup)
    where dDup []        = []
          dDup (tos:stk) = tos:tos:stk

fDROP :: FState -> FState
fDROP = stack_op(dDrop)
    where dDrop []      = []
          dDrop (_:stk) = stk

fSWAP :: FState -> FState
fSWAP = stack_op(dSwap)
    where dSwap []            = []
          dSwap (tos:[])      = tos:[]
          dSwap (tos:nxt:stk) = nxt:tos:stk

fROT :: FState -> FState
fROT = stack_op(dRot)
    where dRot []                = []
          dRot (tos:[])          = tos:[]
          dRot (tos:nxt:[])      = tos:nxt:[]
          dRot (tos:nxt:thd:stk) = thd:tos:nxt:stk

--dsp actions (implements queued dsp graph changes)
dsp_act :: DSPAction -> FState -> IO FState
dsp_act (None) s = return(s)
-- dsp_act (NewMod m) s = do
--     let modinstance = dspCreateMod m
--     putStrLn (show modinstance)
--     return s
-- dsp_act (ListParams m) s = do
--     params <- dspGetParams m
--     putStrLn (show params)
--     return s
-- dsp_act (ListInputs m) s = do
--     ins <- dspGetIns m
--     putStrLn (show ins)
--     return s

--quit loop
--here is were ABORT error checking should occur
fQUIT :: FState -> IO FState
fQUIT s@(FState {abort_flag   = True}) = do
    return(output_append("abort!\n") s {abort_flag = False})
fQUIT s@(FState {input_string = []})   = do
    unstate <- dsp_act (dsp_action s) s
    return(output_append("ok.\n") $ unstate {dsp_action = None})
fQUIT s@(FState {compile_flag = True }) = do
    unstate <- dsp_act (dsp_action s) s
    fQUIT . fCOMPILE $ unstate {dsp_action = None}
fQUIT s@(FState {compile_flag = False}) = do
    unstate <- dsp_act (dsp_action s) s
    fQUIT . fINTERPRET $ unstate {dsp_action = None}


--interpret and parse
fINTERPRET :: FState -> FState
fINTERPRET = fEXECUTE . fFIND . fWORD . fBL

-- problem here is EXECUTE now expects a flag on the stack before the
-- function. probably a good time to think about composite functions acting
-- via the return stack anyway... will currently spoof it with
-- a non-immediate flag.
fEXECUTE :: FState -> FState
fEXECUTE s@(FState {datastack = (FIWord NA:_:_)}) = stack_op(isnum)
                                                  . fDROP
                                                  $ s
    where
        isnum :: FDataStack -> FDataStack
        isnum (FStr "":xs) = xs --ignore trailing whitespace
        isnum (FStr  x:xs) = (FNum (read x) : xs)
--        isnum (FStr x:xs)   = ((numMaybe x) : xs)
--        where
--            numMaybe :: FStr -> FStackItem
--            numMaybe _ = (FNum 3)
fEXECUTE s@(FState {datastack = (_:FFn x:_)}) = x
                                              . fDROP
                                              . fDROP
                                              $ s
fEXECUTE s@(FState {datastack = (_:FCFn x:_)}) = composite x
                                               . fDROP
                                               . fDROP
                                               $ s
    where
        composite :: [FStackItem] -> FState -> FState
        composite ([])   st = st
        composite (f:fs) st = composite fs
                            . fEXECUTE
                            . stack_op(FIWord Not :)
                            . stack_op(f :)
                            $ st
fEXECUTE s = fDROP $ s { abort_flag = True} --set out string?

-- composite is ENTER
-- composite w [] is EXIT

-- nb! if there's a leading space in a phrase, will push the empty list to
-- stack :/
fWORD :: FState -> FState
fWORD s = stack_op(FStr word :)
        . fDROP
        $ s { input_string = str' }
    where
        word  = takeWhile (/= delim)
                $ dropWhile (== delim)
                $ input_string s
        takeS = takeWhile (== delim) $ input_string s
        str'  = drop (1 + length word + length takeS)
                     (input_string s)
        delim = getChar (datastack s)
        getChar (FStr c:stk) = head c

-- nb: could also be a stack op (just pass (dict s) as arg)
fFIND :: FState -> FState
fFIND s = s { datastack = dFIND (datastack s) (dictionary s)  }
    where dFIND [] _          = (FIWord NA):(FCFn []):[]
          dFIND (FStr x:xs) d = (matchImm):(matchDict):xs
            where
                matchD :: [FStackItem]
                matchD = [ fn | (name, imm, fn) <- d
                              , name == x ]
                matchDict = case matchD of
                            []  -> FStr x          --echo
                            fun -> head fun
                matchI :: [FIWord]
                matchI = [ imm | (name, imm, fn) <- d
                               , name == x ]
                matchImm = case matchI of
                           []  -> FIWord NA      --not found
                           fon -> FIWord (head fon)

--compilation
fCOMPILE :: FState -> FState
fCOMPILE = fCEXE . fFIND . fWORD . fBL

fCEXE :: FState -> FState
fCEXE s@(FState {datastack = (FIWord Imm:_)}) = fEXECUTE $ s
fCEXE s@(FState {datastack = (_:FStr "":_)})  = fDROP . fDROP $ s
fCEXE s@(FState {datastack = (_:FStr x:_)})   = fCOMPILEN
                                              . fDROP
                                              $ s
    -- need to compile to dictionary!
    -- also check if it can be numberized, else ABORT"
fCEXE s                                       = fCOMPILEC
                                              . fDROP
                                              $ s

fCOMPILEC :: FState -> FState
fCOMPILEC s@(FState {dictionary = (x:xs)}) =
      fDROP $ s { dictionary = (compileTo x):xs }
      where
          compileTo :: FDictEntry -> FDictEntry
          compileTo (s, f, FCFn x) =
              (s, f, FCFn (x ++ [newd]))
          compileTo (s, f, FFn x) =
              (s, f, FCFn ([FFn x] ++ [newd]))
              -- was a one element dict entry. now a composite
          newd = head $ datastack s

-- does this also need "" protection like fEXECUTE
-- really need to improve the parser in WORD!
fCOMPILEN :: FState -> FState
fCOMPILEN s@(FState {dictionary = (x:xs)}) =
      fDROP $ s { dictionary = (compileTo x):xs }
      where
          compileTo :: FDictEntry -> FDictEntry
          compileTo (st, f, FCFn x) =
              (st, f, FCFn (x ++ [newd $ head $ datastack s]))
          compileTo (st, f, FFn x) =
              (st, f, FCFn ([FFn x] ++ [newd $ head $ datastack s]))
              -- was a one element dict entry. now a composite
          newd :: FStackItem -> FStackItem
          newd (FStr x) = (FNum (read x))

fLEFTBRAK :: FState -> FState
fLEFTBRAK s = s { compile_flag = False }

fRITEBRAK :: FState -> FState
fRITEBRAK s = s { compile_flag = True }

fCREATE :: FState -> FState
fCREATE s@(FState {datastack = (FStr name:xs)}) =
    fDROP $ s { dictionary = coWord : dictionary s }
    where
        coWord :: FDictEntry
        coWord = ( name
                 , Not
                 , FCFn [] )

-- IMMEDIATE
fIMMEDIATE :: FState -> FState
fIMMEDIATE s@(FState {dictionary = (x:xs)}) =
        s { dictionary = (i_flag x) : xs }
        where
            i_flag :: FDictEntry -> FDictEntry
            i_flag (n, _, fn) = (n, Imm, fn)

fPAREN :: FState -> FState
fPAREN = fDROP . fWORD . stack_op(FStr ")" :)


--lists
--fBRACE :: FState -> FState
--fBRACE = stack_op(pList) . fWORD . stack_op(FStr "}" :)
--    where pList x:xs = newList : xs
--newList x =l


--COMPOSITE WORDS
--hand compiled

fCOLON :: FCFn
fCOLON = [ FFn fBL
         , FFn fWORD
         , FFn fRITEBRAK
         , FFn fCREATE
         ]

fSEMIC :: FCFn
fSEMIC = [ FFn fLEFTBRAK ]
