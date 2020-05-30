import Control.Concurrent (forkIO, newEmptyMVar, putMVar, readMVar)
import Control.Exception (evaluate)
import System.Environment (getArgs)
import Data.Time.Clock (getCurrentTime, diffUTCTime)
import Data.Array.IO (IOUArray, newArray, writeArray, getElems)
import Data.Word (Word8)
import System.IO (hPutStrLn, hPutStr, stderr)
import Control.Monad (forM)

x_base = -2.0
y_base = 1.25
side = 2.5
maxCount = 1024

type Args = (Int, Int, Double, IOUArray Int Word8)
--          size * cutOff * delta * image

loopV :: Args -> Int -> Int -> Int -> Int -> Int -> Int -> IO Int
loopV (args@(size, _, delta, image)) i x y w h iterations =
  if i >= h
  then return iterations
  else
    let
      c_im = y_base - delta * fromIntegral (i + y)
      loopH j iterations =
        if j >= w
        then return iterations
        else
          let
            c_re = x_base + delta * fromIntegral (j + x)
            loopP :: Int -> Double -> Double -> IO Int
            loopP count z_re z_im =
              if count < maxCount
              then
                let
                  z_re_sq = z_re * z_re
                  z_im_sq = z_im * z_im
                in
                  if z_re_sq + z_im_sq > 4.0
                  then do writeArray image ((j + x) + (i + y) * size) 1
                          return count
                  else loopP (count + 1)
                             (z_re_sq - z_im_sq + c_re)
                             (2.0 * z_re * z_im + c_im)
              else return count
          in
            do count <- loopP 0 c_re c_im
               loopH (j+1) (iterations + count)
    in
      do iterations2 <- loopH 0 iterations
         loopV args (i+1) x y w h iterations2

mandelbrot (args@(_, cutOff, _, _)) x y w h =
    if w <= cutOff && h <= cutOff
    then loopV args 0 x y w h 0
    else if w >= h
    then let w2 = w `div` 2
         in do c <- newEmptyMVar
               forkIO $ mandelbrot args (x + w2) y (w - w2) h >>= putMVar c
               r <- mandelbrot args x y w2 h
               n <- readMVar c
               return $ r + n
    else let h2 = h `div` 2
         in do c <- newEmptyMVar
               forkIO $ mandelbrot args x (y + h2) w (h - h2) >>= putMVar c
               r <- mandelbrot args x y w h2
               n <- readMVar c
               return $ r + n

doit (args@(size, _, _, _)) =
    mandelbrot args 0 0 size size

rep args 0 = return ()
rep (args@(size, cutOff, _, image)) n =
  do t1 <- getCurrentTime
     r <- doit args
     t2 <- getCurrentTime
{-
     hPutStrLn stderr $ "P1\n" ++ show size ++ " " ++ show size
     getElems image >>= \x -> forM x $ hPutStr stderr . show
-}
     putStrLn $ " - {result: " ++ show 0 ++ ", time: "
                ++ show (t2 `diffUTCTime` t1) ++ "}"
     rep args (n - 1) 

main =
  do args <- getArgs
     let repeat = case args of x:_ -> read x :: Int; otherwise -> 10
     let size = case args of _:x:_ -> read x :: Int; otherwise -> 2048
     let cutOff = case args of _:_:x:_ -> read x :: Int; otherwise -> 8
     let delta = side / fromIntegral size
     do image <- newArray (0, size * size) 0
        putStrLn $ " bench: mandelbrot_ghc_forkIO"
        putStrLn $ " size: " ++ show size
        putStrLn $ " cutoff: " ++ show cutOff
        putStrLn $ " results:"
        rep (size, cutOff, delta, image) repeat 
