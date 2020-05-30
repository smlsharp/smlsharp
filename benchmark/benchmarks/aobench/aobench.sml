(*
 * aobench is originally written by Syoyo Fujita.
 * https://code.google.com/archive/p/aobench/
 * https://github.com/syoyo/aobench
 *
 * aobench C code is licensed under 2-clause BSD.
 *
 * Copyright 2009-2014, Syoyo Fujita All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above
 *     copyright notice, this list of conditions and the following
 *     disclaimer in the documentation and/or other materials provided
 *     with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Translated into Standard ML by Katsuhiro Ueno.
 *)

structure AOBench : sig
  val doit : unit -> unit
  val testit : unit -> unit
end =
struct

  (*
   * The implementation of drand48 is borrowed from OpenBSD.
   *
   * Copyright (c) 1993 Martin Birgmeier
   * All rights reserved.
   *
   * You may redistribute unmodified or modified versions of this source
   * code provided that the above copyright notice and this and the
   * following conditions are retained.
   *
   * This software is provided ``as is'', and comes with no warranties
   * of any kind. I shall in no event be liable for anything that happens
   * to anyone/anything when using this software.
   *
   * Translated into Standard ML by Katsuhiro Ueno.
   *)
  val seed0 = ref 0wx330e
  val seed1 = ref 0wxabcd
  val seed2 = ref 0wx1234
  fun drand48 () =
      let
        val accu = 0wxe66d * !seed0 + 0wx000b
        val tmp0 = Word.andb (accu, 0wxffff)
        val accu = Word.>> (accu, 0w16)
        val accu = accu + 0wxe66d * !seed1 + 0wxdeec * !seed0
        val tmp1 = Word.andb (accu, 0wxffff)
        val accu = Word.>> (accu, 0w16)
        val accu = accu + 0wxe66d * !seed2 + 0wxdeec * !seed1 + 0wx0005 * !seed0
        val tmp2 = Word.andb (accu, 0wxffff)
      in
        seed0 := tmp0;
        seed1 := tmp1;
        seed2 := tmp2;
        Real.fromManExp {man = real (Word.toIntX tmp0), exp = ~48}
        + Real.fromManExp {man = real (Word.toIntX tmp1), exp = ~32}
        + Real.fromManExp {man = real (Word.toIntX tmp2), exp = ~16}
      end

  val WIDTH = 256
  val HEIGHT = 256
  val NSUBSAMPLES = 2
  val NA0_SAMPLES = 8

  type vec = {x : real, y : real, z : real}
  type Isect = {t : real, p : vec, n : vec, hit : bool}
  type Sphere = {center : vec, radius : real}
  type Plane = {p : vec, n : vec}
  type Ray = {org : vec, dir : vec}

  val sphere0 = {center = {x = ~2.0, y = 0.0, z = ~3.5}, radius = 0.5}
  val sphere1 = {center = {x = ~0.5, y = 0.0, z = ~3.0}, radius = 0.5}
  val sphere2 = {center = {x =  1.0, y = 0.0, z = ~2.2}, radius = 0.5}
  val plane =
      {p = {x = 0.0, y = ~0.5, z = 0.0}, n = {x = 0.0, y = 1.0, z = 0.0}}

  fun vdot ({x=x0, y=y0, z=z0}:vec, {x=x1, y=y1, z=z1}:vec) =
      x0 * x1 + y0 * y1 + z0 * z1

  fun vcross ({x=x0, y=y0, z=z0}:vec, {x=x1, y=y1, z=z1}:vec) =
      {x = y0 * z1 - z0 * y1,
       y = z0 * x1 - x0 * z1,
       z = x0 * y1 - y0 * x1}

  fun vnormalize (vec as {x, y, z}:vec) =
      let
        val length = Math.sqrt (vdot (vec, vec))
      in
        if abs length > 1.0e~17
        then {x = x / length, y = y / length, z = z / length}
        else vec
      end

  fun ray_sphere_intersect (isect, {org, dir}:Ray, {center, radius}:Sphere) =
      let
        val rs = {x = #x org - #x center,
                  y = #y org - #y center,
                  z = #z org - #z center}
        val B = vdot (rs, dir)
        val C = vdot (rs, rs) - radius * radius
        val D = B * B - C
      in
        if D > 0.0 then
          let val t = ~B - Math.sqrt D in
            if t > 0.0 andalso t < #t isect then
              let
                val p = {x = #x org + #x dir * t,
                         y = #y org + #y dir * t,
                         z = #z org + #z dir * t}
                val n = {x = #x p - #x center,
                         y = #y p - #y center,
                         z = #z p - #z center}
              in
                {t = t, hit = true, p = p, n = vnormalize n}
              end
            else isect
          end
        else isect
      end

  fun ray_plane_intersect (isect, {org, dir}:Ray, {p, n}:Plane) =
      let
        val d = ~(vdot (p, n))
        val v = vdot (dir, n)
      in
        if abs v < 1.0e~17 then isect else
        let
          val t = ~(vdot (org, n) + d) / v;
        in
          if t > 0.0 andalso t < #t isect then
            {t = t,
             hit = true,
             p = {x = #x org + #x dir * t,
                  y = #y org + #y dir * t,
                  z = #z org + #z dir * t},
             n = n}
          else isect
        end
      end

  fun orthoBasis (n as {x, y, z}:vec) =
      let
        val vec2 = n
        val vec1 =
            if x < 0.6 andalso x > ~0.6
            then {x = 1.0, y = 0.0, z = 0.0}
            else if y < 0.6 andalso y > ~0.6
            then {x = 0.0, y = 1.0, z = 0.0}
            else if z < 0.6 andalso z > ~0.6
            then {x = 0.0, y = 0.0, z = 1.0}
            else {x = 1.0, y = 0.0, z = 0.0}
        val vec0 = vnormalize (vcross (vec1, vec2))
        val vec1 = vnormalize (vcross (vec2, vec0))
      in
        (vec0, vec1, vec2)
      end

  fun ambient_occlusion (isect:Isect) =
      let
        val ntheta = NA0_SAMPLES
        val nphi = NA0_SAMPLES
        val eps = 0.0001
        val p = {x = #x (#p isect) + eps * #x (#n isect),
                 y = #y (#p isect) + eps * #y (#n isect),
                 z = #z (#p isect) + eps * #z (#n isect)}
        val basis = orthoBasis (#n isect)
        fun loopI i occlusion =
            if i >= nphi then occlusion else
            let
              val theta = Math.sqrt (drand48 ())
              val phi = 2.0 * Math.pi * (drand48 ())
              val x = Math.cos phi * theta
              val y = Math.sin phi * theta
              val z = Math.sqrt (1.0 - theta * theta)
              val rx = x * #x (#1 basis) + y * #x (#2 basis) + z * #x (#3 basis)
              val ry = x * #y (#1 basis) + y * #y (#2 basis) + z * #y (#3 basis)
              val rz = x * #z (#1 basis) + y * #z (#2 basis) + z * #z (#3 basis)
              val ray = {org = p, dir = {x = rx, y = ry, z = rz}}
              val occIsect = {t = 1.0e17,
                              hit = false,
                              n = {x = 0.0, y = 0.0, z = 0.0},
                              p = {x = 0.0, y = 0.0, z = 0.0}}
              val occIsect = ray_sphere_intersect (occIsect, ray, sphere0)
              val occIsect = ray_sphere_intersect (occIsect, ray, sphere1)
              val occIsect = ray_sphere_intersect (occIsect, ray, sphere2)
              val occIsect = ray_plane_intersect (occIsect, ray, plane)
            in
              if #hit occIsect
              then loopI (i + 1) (occlusion + 1.0)
              else loopI (i + 1) occlusion
            end
        fun loopJ j occlusion =
            if j >= ntheta then occlusion
            else loopJ (j + 1) (loopI 0 occlusion)
        val occlusion = loopJ 0 0.0
        val occlusion =
            (real (ntheta * nphi) - occlusion) / real (ntheta * nphi)
      in
        {x = occlusion, y = occlusion, z = occlusion}
      end

  fun clamp f =
      let
        val i = trunc (f * 255.5)
        val i = if i < 0 then 0 else i
        val i = if i > 255 then 255 else i
      in
        Word8.fromInt i
      end

  fun render (w, h, nsubsamples) =
      let
        val fimg = Array.array (w * h * 3, 0.0)
        val img = Word8Array.array (w * h * 3, 0w0)
        fun loopY y =
            if y >= h then () else
            let
              fun loopX x =
                  if x >= w then () else
                  let
                    fun loopV v =
                        if v >= nsubsamples then () else
                        let
                          fun loopU u =
                              if u >= nsubsamples then () else
                              let
                                val px = (real x
                                          + real u / real nsubsamples
                                          - real w / 2.0)
                                         / (real w / 2.0)
                                val py = ~(real y
                                           + real v / real nsubsamples
                                           - real h / 2.0)
                                         / (real h / 2.0)
                                val ray = {org = {x = 0.0, y = 0.0, z = 0.0},
                                           dir = vnormalize
                                                   {x = px, y = py, z = ~1.0}}
                                val isect = {t = 1.0e17,
                                             hit = false,
                                             n = {x = 0.0, y = 0.0, z = 0.0},
                                             p = {x = 0.0, y = 0.0, z = 0.0}}
                                val isect = ray_sphere_intersect
                                              (isect, ray, sphere0)
                                val isect = ray_sphere_intersect
                                              (isect, ray, sphere1)
                                val isect = ray_sphere_intersect
                                              (isect, ray, sphere2)
                                val isect = ray_plane_intersect
                                              (isect, ray, plane)
                              in
                                if #hit isect then
                                  let
                                    val col = ambient_occlusion isect
                                  in
                                    Array.update
                                      (fimg, 3 * (y * w + x) + 0,
                                       Array.sub
                                         (fimg, 3 * (y * w + x) + 0) + #x col);
                                    Array.update
                                      (fimg, 3 * (y * w + x) + 1,
                                       Array.sub
                                         (fimg, 3 * (y * w + x) + 1) + #y col);
                                    Array.update
                                      (fimg, 3 * (y * w + x) + 2,
                                       Array.sub
                                         (fimg, 3 * (y * w + x) + 2) + #z col)
                                  end
                                else ();
                                loopU (u + 1)
                              end
                        in
                          loopU 0;
                          loopV (v + 1)
                        end
                  in
                    loopV 0;
                    Array.update
                      (fimg,
                       3 * (y * w + x) + 0,
                       Array.sub
                         (fimg,
                          3 * (y * w + x) + 0)
                       / real (nsubsamples * nsubsamples));
                    Array.update
                      (fimg,
                       3 * (y * w + x) + 1,
                       Array.sub
                         (fimg,
                          3 * (y * w + x) + 1)
                       / real (nsubsamples * nsubsamples));
                    Array.update
                      (fimg,
                       3 * (y * w + x) + 2,
                       Array.sub
                         (fimg,
                          3 * (y * w + x) + 2)
                       / real (nsubsamples * nsubsamples));
                    Word8Array.update
                      (img,
                       3 * (y * w + x) + 0,
                       clamp (Array.sub (fimg, 3 * (y * w + x) + 0)));
                    Word8Array.update
                      (img,
                       3 * (y * w + x) + 1,
                       clamp (Array.sub (fimg, 3 * (y * w + x) + 1)));
                    Word8Array.update
                      (img,
                       3 * (y * w + x) + 2,
                       clamp (Array.sub (fimg, 3 * (y * w + x) + 2)));
                    loopX (x + 1)
                  end
            in
              loopX 0;
              loopY (y + 1)
            end
      in
        loopY 0;
        img
      end

  fun saveppm (fname, w, h, img) =
      let
        val fp = BinIO.openOut fname
      in
        BinIO.output (fp, Byte.stringToBytes "P6\n");
        BinIO.output
          (fp,
           Byte.stringToBytes (Int.toString w ^ " " ^ Int.toString h ^ "\n"));
        BinIO.output (fp, Byte.stringToBytes "255\n");
        BinIO.output (fp, Word8Array.vector img);
        BinIO.closeOut fp
      end

  fun doit () =
      ignore (render (WIDTH, HEIGHT, NSUBSAMPLES))

  fun testit () =
      let
        val img = render (WIDTH, HEIGHT, NSUBSAMPLES)
      in
        saveppm ("ao.ppm", WIDTH, HEIGHT, img)
      end

end
