module Dict where

import FTypes

-- helper functions
stack_op :: (FDataStack -> FDataStack) -> FState -> FState
stack_op f s = s { datastack = f (datastack s) }

stack_pop :: FDataStack -> FDataStack
stack_pop = drop 1

-- DICTIONARY

-- map of native functions
-- must manually add new native words here :/

native_dict = [ (".S"   ,False, FFn fDOTESS   )
              , ("."    ,False, FFn fDOT      )
              , ("BL"   ,False, FFn fBL       )
              , ("*"    ,False, FFn fSTAR     )
              , ("+"    ,False, FFn fADD      )
              , ("-"    ,False, FFn fSUB      )
              , ("/"    ,False, FFn fDIV      )
              , ("MAX"  ,False, FFn fMAX      )
              , ("MIN"  ,False, FFn fMIN      )
              , ("DUP"  ,False, FFn fDUP      )
              , ("DROP" ,False, FFn fDROP     )
              , ("SWAP" ,False, FFn fSWAP     )
              , ("OVER" ,False, FFn fOVER     )
              , ("ROT"  ,False, FFn fROT      )
              , ("NIP"  ,False, FFn fNIP      )
              , ("TUCK" ,False, FFn fTUCK     )
              , ("WORD" ,False, FFn fWORD     )
              , ("FIND" ,False, FFn fFIND     )
              , ("["    ,True , FFn fLEFTBRAK )
              , ("]"    ,False, FFn fRITEBRAK )
              , (":"    ,False, FCFn fCOLON   )
              , (";"    ,True , FCFn fSEMIC   )
              , (":q"   ,True , FFn fCOLONQ   )
              ]

-- force quit
fCOLONQ :: FState -> FState
fCOLONQ s = s { quit_flag = True }

-- printing
fDOTESS :: FState -> FState
fDOTESS s@(FState {datastack=[]}) =
        s { output_string = output_string s
          ++ "stack's empty mate"
          ++ "\n" }
fDOTESS s = s { output_string = output_string s
                 ++ "<len: "
                 ++ (show $ length (datastack s))
                 ++ "> "
                 ++ (show (datastack s))
                 ++ " nice stack =]"
                 ++ "\n" }

fDOT :: FState -> FState
fDOT s@(FState {datastack=[]}) =
        s { output_string = "stack's empty mate" }
fDOT s = s { datastack = stack_pop( datastack s  )
           , output_string = output_string s ++ getPancake( datastack s ) ++ "\n"
           }
         where getPancake (cake:cakes) = show(cake) ++ " pancake!"

fDOTG :: FState -> FState
fDOTG s = s { output_string = output_string s
                ++ "call to c and print the whole graph!"
                ++ "\n"
            }


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

fOVER :: FState -> FState
fOVER = fTUCK . fSWAP

fROT :: FState -> FState
fROT = stack_op(dRot)
    where dRot []                = []
          dRot (tos:[])          = tos:[]
          dRot (tos:nxt:[])      = tos:nxt:[]
          dRot (tos:nxt:thd:stk) = thd:tos:nxt:stk

fNIP :: FState -> FState
fNIP = fDROP . fSWAP

fTUCK :: FState -> FState
fTUCK = fSWAP . fROT . fDUP



--quit loop
fQUIT :: FState -> FState
fQUIT s@(FState {input_string = []}) = s
fQUIT s@(FState {compile_flag = True }) = fQUIT . fCOMPILE $ s
fQUIT s@(FState {compile_flag = False}) = fQUIT . fINTERPRET $ s


--interpret and parse
fINTERPRET :: FState -> FState
fINTERPRET = fEXECUTE . fDROP . fFIND . fWORD . fBL

fEXECUTE :: FState -> FState
fEXECUTE s@(FState {datastack = (FNum x:xs)}) = s
fEXECUTE s@(FState {datastack = (FFn  x:xs)}) = x s {
    datastack = stack_pop $ datastack s }
fEXECUTE s@(FState {datastack = (FCFn x:xs)}) =
    composite x s {datastack = stack_pop $ datastack s}
    where composite :: [FStackItem] -> FState -> FState
          composite ([])   st = st
          composite (f:fs) st = composite fs $ fEXECUTE st {
            datastack = f : datastack st }

-- composite is ENTER
-- 151 is EXIT

fWORD :: FState -> FState
fWORD s = s { datastack = (FStr word):(stack_pop $ datastack s)
            , input_string = str' }
    where word  = takeWhile (/= delim) (input_string s)
          str'  = drop (1 + length word) (input_string s)
          delim = getChar (datastack s)
          getChar (FStr c:stk) = head c

fFIND :: FState -> FState
fFIND s = s { datastack = dFIND (datastack s) (dictionary s)  }
    where dFIND [] _          = []
          dFIND (FStr x:xs) d = (matchFlag):(matchDict):xs
            where matchIt :: [FStackItem]
                  matchIt = [ fn | (name, flag, fn) <- d
                                 , name == x ]
                  matchDict = case matchIt of
                            []  -> FNum (read x)
                            fun -> head fun
                  matchF :: [FCFlag]
                  matchF = [ flag | (name, flag, fn) <- d
                                  , name == x ]
                  matchFlag = case matchF of
                            []  -> FCFlag False
                            fon -> FCFlag (head fon)

--compilation
fCOMPILE :: FState -> FState
fCOMPILE = fCEXE . fFIND . fWORD . fBL

fCEXE :: FState -> FState
fCEXE s@(FState {datastack = (FCFlag True:xs)}) =
    fEXECUTE . fDROP $ s
fCEXE s@(FState {datastack = (x:FNum xx:xs)}) =
    fDROP $ s
fCEXE s =
    fCOMPILEC . fDROP $ s

fCOMPILEC :: FState -> FState
fCOMPILEC s@(FState {dictionary = (x:xs)}) =
    s { dictionary = (compileTo x):xs
      , datastack = stack_pop $ datastack s}
    where compileTo :: FDictEntry -> FDictEntry
          compileTo (s, f, FCFn x) =
              (s, f, FCFn (x ++ [newd]))
          newd = head $ datastack s

fLEFTBRAK :: FState -> FState
fLEFTBRAK s = s { compile_flag = False }

fRITEBRAK :: FState -> FState
fRITEBRAK s = s { compile_flag = True }

fCREATE :: FState -> FState
fCREATE s@(FState {datastack = (FStr name:xs)}) =
    s { dictionary = coWord : dictionary s
      , datastack  = stack_pop $ datastack s }
    where coWord :: FDictEntry
          coWord = ( name
                   , False
                   , FCFn [] )

-- IMMEDIATE
fPAREN :: FState -> FState
fPAREN = fDROP . fWORD . stack_op(FStr ")" :)


--lists
--fBRACE :: FState -> FState
--fBRACE = stack_op(pList) . fWORD . stack_op(FStr "}" :)
--    where pList x:xs = newList : xs
--newList x =l


--COMPOSITE WORDS
--hand compiled
--
--note the runtime compilation example of CUBED
--after compilation works, should create a transformer
--that does the cubWord elements to avoid repetition
--
--after that works, can refactor to allow words to be
--entered as text strings that use the compilation step
--to add them to dictionary at haskell-compile time


fCOLON :: [FStackItem]
fCOLON = [ FFn fBL
         , FFn fWORD
         , FFn fRITEBRAK
         , FFn fCREATE ]

fSEMIC :: [FStackItem]
fSEMIC = [ FFn fLEFTBRAK ]

--runtime compilation
addCubed :: FState -> FState
addCubed s = s { dictionary = cubWord : dictionary s }
    where cubWord :: FDictEntry
          cubWord = ( "CUBED"
                    , False
                    , FCFn [ FFn fDUP
                           , FFn fDUP
                           , FFn fSTAR
                           , FFn fSTAR])

