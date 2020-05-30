import Control.Concurrent (forkIO, newEmptyMVar, putMVar, readMVar)
import System.Environment (getArgs)
import Data.Time.Clock (getCurrentTime, diffUTCTime)
import Control.Monad (replicateM, forM)
import Control.Monad.State (State, evalState, get, modify')
import Data.Array.IO (IOUArray, newListArray, newArray_, writeArray, readArray,
                      getElems)
import System.IO (hPutStrLn, stderr)

copy :: IOUArray Int Double -> Int -> Int -> IOUArray Int Double -> Int -> IO ()
copy a b e d j =
  if e < b then return ()
  else do readArray a b >>= writeArray d j
          copy a (b+1) e d (j+1)

search :: IOUArray Int Double -> Int -> Int -> Double -> IO Int
search a b e k =
  if e < b then return $ e + 1
  else if e == b
  then do x <- readArray a e
          if k < x then return e else return $ e + 1
  else do let m = (b + e) `div` 2
          x <- readArray a m
          if k < x then search a b m k else search a (m+1) e k

merge cutOff a b1 e1 b2 e2 d j =
  if e1 < b1 then copy a b2 e2 d j
  else if e2 < b2 then copy a b1 e1 d j
  else if e1 - b1 < e2 - b2 then merge cutOff a b2 e2 b1 e1 d j
  else
    do
      x <- readArray a e1
      y <- readArray a b2
      if x <= y
      then do copy a b1 e1 d j
              copy a b2 e2 d (j+(e1-b1+1))
      else
        do
          x <- readArray a e2
          y <- readArray a b1
          if x <= y
          then do copy a b2 e2 d j
                  copy a b1 e1 d (j+(e2-b2+1))
          else
            do let m = (b1 + e1) `div` 2
               n <- readArray a m >>= search a b2 e2
               if e1 - b1 <= cutOff then
                 do merge cutOff a b1 m b2 (n-1) d j
                    merge cutOff a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
               else
                 do c <- newEmptyMVar
                    forkIO $ merge cutOff a b1 m b2 (n-1) d j >>= putMVar c
                    merge cutOff a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
                    readMVar c

cilksort cutOff a b e d j =
  if e <= b then return ()
  else
    let q2 = (b + e) `div` 2
        q1 = (b + q2) `div` 2
        q3 = (q2 + 1 + e) `div` 2
    in if e - b <= cutOff then
         do cilksort cutOff a b q1 d j
            cilksort cutOff a (q1+1) q2 d (j+(q1-b+1))
            cilksort cutOff a (q2+1) q3 d (j+(q2-b+1))
            cilksort cutOff a (q3+1) e d (j+(q3-b+1))
            merge cutOff a b q1 (q1+1) q2 d j
            merge cutOff a (q2+1) q3 (q3+1) e d (j+(q2-b+1))
            merge cutOff d b q2 (q2+1) e a b
       else
         do c1 <- newEmptyMVar
            forkIO $ do
              c <- newEmptyMVar
              forkIO $ cilksort cutOff a b q1 d j >>= putMVar c
              cilksort cutOff a (q1+1) q2 d (j+(q1-b+1))
              readMVar c
              merge cutOff a b q1 (q1+1) q2 d j >>= putMVar c1
            c2 <- newEmptyMVar
            forkIO $ cilksort cutOff a (q2+1) q3 d (j+(q2-b+1)) >>= putMVar c2
            cilksort cutOff a (q3+1) e d (j+(q3-b+1))
            readMVar c2
            merge cutOff a (q2+1) q3 (q3+1) e d (j+(q2-b+1))
            readMVar c1
            merge cutOff d b q2 (q2+1) e a b

pmrand :: State Int Int
pmrand =
  do modify' 
       (\p ->  
          let hi = p `div` (2147483647 `div` 48271)
              lo = p `mod` (2147483647 `div` 48271)
              test = 48271 * lo - (2147483647 `mod` 48271) * hi
          in if test > 0 then test else test + 2147483647)
     get

randReal =
  do x <- pmrand
     y <- pmrand
     return $ fromIntegral x / fromIntegral y

init_a :: Int -> IO (IOUArray Int Double)
init_a size =
  newListArray (0, size - 1) $ evalState (replicateM size randReal) 1

init_d :: Int -> IO (IOUArray Int Double)
init_d size =
  newArray_ (0, size - 1)

doit size cutOff a d =
  cilksort cutOff a 0 (size - 1) d 0

rep size cutOff 0 = return ()
rep size cutOff n =
  do a <- init_a size
     d <- init_d size
     t1 <- getCurrentTime
     doit size cutOff a d
     t2 <- getCurrentTime
{-
     getElems a >>= \x -> forM x $ hPutStrLn stderr . show
-}
     putStrLn $ " - {result: " ++ show 0 ++ ", time: "
                ++ show (t2 `diffUTCTime` t1) ++ "}"
     rep size cutOff (n - 1)

main =
  do args <- getArgs
     let repeat = case args of x:_ -> read x :: Int; otherwise -> 10
     let size = case args of _:x:_ -> read x :: Int; otherwise -> 4194304
     let cutOff = case args of _:_:x:_ -> read x :: Int; otherwise -> 32
     putStrLn $ " bench: cilksort_ghc_forkIO"
     putStrLn $ " size: " ++ show size
     putStrLn $ " cutoff: " ++ show cutOff
     putStrLn $ " results:"
     rep size cutOff repeat
