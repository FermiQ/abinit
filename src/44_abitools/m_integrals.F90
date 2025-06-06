!!****m* ABINIT/m_integrals
!! NAME
!!  m_integrals
!!
!! FUNCTION
!!  Helper functions to compute integrals
!!
!! COPYRIGHT
!!  Copyright (C) 2010-2025 ABINIT group (Camilo Espejo)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

module m_integrals

 use defs_basis
 use m_errors
 use m_abicore

 use m_numeric_tools,   only : simpson_int
 use m_macroave,        only : four1

 implicit none

! private


 public :: radsintr
!!***

contains
!!***

!!****f* ABINIT/radsintr
!! NAME
!!  radsintr
!!
!! FUNCTION
!! Computes the sine transformation of a radial function F(r) to V(q).
!! Computes integrals using corrected Simpson integration on a linear grid.
!!
!! INPUTS
!!  funr(mrgrid)=F(r) on radial grid
!!  mqgrid=number of grid points in q from 0 to qmax
!!  mrgrid=number of grid points in r from 0 to rmax
!!  qgrid(mqgrid)=q grid values (bohr**-1).
!!  rgrid(mrgrid)=r grid values (bohr)
!!  rfttype=Type of radial sin Fourier transform   
!!
!! OUTPUT
!!  funq(mqgrid)=\int_0^inf 4\pi\frac{\sin(2\pi r)}{2\pi r}r^2F(r)dr
!!  yq1, yqn: d/dq (F(q)) at the ends of the interval
!!
!! SIDE EFFECTS
!!
!! NOTES
!!  This routine is a modified version of /src/65_psp/psp7lo.F90
!!
!! SOURCE

subroutine radsintr(funr,funq,mqgrid,mrgrid,qgrid,rgrid,yq1,yqn,rfttype)

!Arguments ------------------------------------
!scalars
 integer , intent(in)  :: mqgrid,mrgrid,rfttype
 real(dp), intent(out) :: yq1,yqn
!arrays
 real(dp), intent(in)  :: funr(0:mrgrid),qgrid(0:mqgrid),rgrid(0:mrgrid)
 real(dp), intent(out) :: funq(0:mqgrid)
!Local variables-------------------------------
character(len=512) :: msg
!scalars
 integer :: iq,ir,irmax,jr,nq
 real(dp) :: arg,cc,dq,dr,fr,qmax,qq,r0tor1,r1torm,rmax,rmtoin,rn,rr,rstep
 logical :: begin_r0
!arrays
 real(dp),allocatable :: ff(:),intg(:),rzf(:)
 real(dp) :: fn(2,0:2*mrgrid),pp(2)

! *************************************************************************

 select case(rfttype)

 case(1)
   rstep=rgrid(2)-rgrid(1)
   rmax = rgrid(mrgrid)
  ! rmax=min(20._dp,rgrid(mrgrid))
   irmax=int(tol8+rmax/rstep)+1
  
  !Particular case of a null fuction to transform
   if (maxval(abs(funr(1:irmax)))<=1.e-20_dp) then
     funq=zero;yq1=zero;yqn=zero
     return
   end if
  
   ABI_MALLOC(ff,(mrgrid))
   ABI_MALLOC(intg,(mrgrid))
   ABI_MALLOC(rzf,(mrgrid))
   ff=zero;rzf=zero
  
  !Is mesh beginning with r=0 ?
   begin_r0=(rgrid(1)<1.e-20_dp)
  
  !Store r.F(r)
   do ir=1,irmax
     ff(ir)=rgrid(ir)*funr(ir) !ff is part of the integrand
   end do
  
  !===========================================
  !=== Compute v(q) for q=0 separately
  !===========================================
  
  !Integral from 0 to r1 (only if r1<>0)
   r0tor1=zero;if (.not.begin_r0) r0tor1=(funr(1)*third)*rgrid(1)**three
  
  !Integral from r1 to rmax
   r1torm = zero
   do ir=1,irmax
     if (abs(ff(ir))>1.e-20_dp) then
       rzf(ir)=rgrid(ir)*ff(ir) !sin(2\pi*q*r)/(2*\pi*q*r)-->1 for q=0
     end if                     !so the integrand is 4*\pi*r^2*F(r)
     r1torm = r1torm + rzf(ir)
   end do
  ! call simpson_int(mrgrid,rstep,rzf,intg)
  ! r1torm=intg(mrgrid)
  ! r1torm = r1torm*rstep 
  !Integral from rmax to infinity
  !This part is neglected... might be improved.
   rmtoin=zero
  
  !Sum of the three parts
  
   funq(1)=four_pi*(r0tor1+r1torm+rmtoin)
  
  !===========================================
  !=== Compute v(q) for other q''s
  !===========================================
  
  !Loop over q values
   do iq=2,mqgrid
     arg=two_pi*qgrid(iq)
  
  !  Integral from 0 to r1 (only if r1<>0)
     r0tor1=zero
     if (.not.begin_r0) r0tor1=(funr(1)/arg) &
  &   *(sin(arg*rgrid(1))/arg-rgrid(1)*cos(arg*rgrid(1)))
  
  !  Integral from r1 to rmax
     rzf=zero
     r1torm = zero
     do ir=1,irmax
       if (abs(ff(ir))>1.e-20_dp) then 
         rzf(ir)=sin(arg*rgrid(ir))*ff(ir)
       end if
       r1torm = r1torm + rzf(ir) 
     end do
  !   r1torm = r1torm*rstep 
  !   call simpson_int(mrgrid,rstep,rzf,intg)
  !   r1torm=intg(mrgrid)
     
  !  Integral from rmax to infinity
  !  This part is neglected... might be improved.
     rmtoin=zero
  
  !  Store F(q)
     funq(iq) = two/qgrid(iq)*(r0tor1+r1torm+rmtoin)
   end do
  
  
  !===========================================
  !=== Compute derivatives of F(q)
  !=== at ends of interval
  !===========================================
  
  !yq(0)=zero
   yq1=zero
  
  !yp(qmax)=$
   arg=two_pi*qgrid(mqgrid)
  
  !Integral from 0 to r1 (only if r1<>0)
   r0tor1=zero
   if (.not.begin_r0) r0tor1=(funr(1)/arg) &
  & *(sin(arg*rgrid(1))*(rgrid(1)**2-three/arg**2) &
  & +three*rgrid(1)*cos(arg*rgrid(1))/arg)
  
  !Integral from r1 to rmax
   do ir=1,irmax
     if (abs(ff(ir))>1.e-20_dp) rzf(ir)=(rgrid(ir)*cos(arg*rgrid(ir)) &
  &   -sin(arg*rgrid(ir))/arg)*ff(ir)
   end do
   call simpson_int(mrgrid,rstep,rzf,intg)
   r1torm=intg(mrgrid)
  
  !Integral from rmax to infinity
  !This part is neglected... might be improved.
   rmtoin=zero
  
  !Sum of the three parts
   yqn=(four*pi/qgrid(mqgrid))*(r0tor1+r1torm+rmtoin)
  
   ABI_FREE(ff)
   ABI_FREE(intg)
   ABI_FREE(rzf)

 case(2)  

       rmax = rgrid(mrgrid)
       nq = mrgrid  !NQ = NR
       dr = rgrid(mrgrid) / mrgrid !RMAX / NR
       dq = pi / rmax
       qmax = nq * dq
       cc = dr / sqrt(2 * pi)
       pp(1) =  0.0_dp
       pp(2) = -1.0_dp
! C Initialize accumulation array -------------------------------------
       do iq = 0,nq
         funq(iq) = 0.0_dp !gg(iq) = 0.0_dp
       end do
! C -------------------------------------------------------------------
! 
! C Iterate on terms of the j_l(q*r) polynomial -----------------------
!       DO N = 0,L
! 
! C       Set up function to be fast fourier transformed
         fn(1,0) = 0.0_dp
         fn(2,0) = 0.0_dp
         do jr = 1, 2*mrgrid-1
 
           if (jr .lt. mrgrid) then
             ir = jr
             rr = ir * dr
             fr = funr(ir)
           elseif (jr .eq. mrgrid) then
             ir = jr
             rr = ir * dr
             fr = 0.0_dp
           else
             ir = 2*mrgrid - jr
             rr = - (ir * dr)
             fr = funr(ir) !* (-1.D0)**L
           end if
 
! C         Find  r**2 * r**n / r**(l+1)
           rn = rr !**(N-L+1)
 
           fn(1,jr) = cc * fr * rn * pp(1)
           fn(2,jr) = cc * fr * rn * pp(2)
         end do
 
! C       Perform one-dimensional complex FFT
! !
! !       Only the elements from 0 to 2*NR-1 of FN are used.
! !       (a total of 2*NR). Four1 will receive a one-dimensional
! !       array of size 2*NR.
! !
         call four1( fn, 2*mrgrid, +1 )
! 
! C       Accumulate contribution
         do iq = 1,nq
           qq = iq * dq
           funq(iq) = ( funq(iq) + fn(1,iq) ) / qq
         end do
! 
!       ENDDO
! C -------------------------------------------------------------------
! 
! C Special case for Q=0 ---------------------------------------------
         funq(0) = 0.0_dp
        !gg(0) = 0.0_dp
     !  if ( L .EQ. 0 ) THEN
         do ir = 1,mrgrid
           rr = ir * dr
           funq(0) = funq(0) + rr*rr * funr(ir)
         end do
         funq(0) = funq(0) * 2.0_dp * cc
     !  ENDIF
 case default 
   
   write(msg,'(2x,a,1x,i2)') " Unknown radial sine FFT type", rfttype
   ABI_ERROR(msg)

 end select

end subroutine radsintr

end module m_integrals
!!***
