!!****m* ABINIT/m_out_spg_anal
!! NAME
!!  m_out_spg_anal
!!
!! FUNCTION
!!
!!
!! COPYRIGHT
!!  Copyright (C) 1998-2025 ABINIT group (DCA, XG, GMR)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

module m_out_spg_anal

 use defs_basis
 use m_results_out
 use m_dtset
 use m_abicore
 use m_errors

 use m_symfind,   only : symfind_expert, symanal, symlatt
 use m_geometry,  only : metric, mkrdim
 use m_spgdata,   only : prtspgroup

 implicit none

 private
!!***

 public :: out_spg_anal
!!***

contains
!!***

!!****f* ABINIT/out_spg_anal
!! NAME
!! out_spg_anal
!!
!! FUNCTION
!! Perform final spacegroup analysis of the results of ABINIT, for each dataset.
!! Compare with the initial one, and perform analysis, with adequate warning if there was a change.
!! Possibly echo spacegroup for all dtsets and possibly all images
!!
!! INPUTS
!!  dtsets(0:ndtset_alloc)=<type datafiles_type>contains all input variables
!!  iout=unit number for echoed output - the echo is done to std_out anyhow.
!!  ndtset=number of datasets
!!  ndtset_alloc=number of datasets, corrected for allocation of at least
!!   one data set. Use for most dimensioned arrays.
!!  echo_spgroup = not relevant anymore, as at present set to 1 in the calling routine.
!!      (0 => write ;  1 => echo of spacegroup for all dtsets and possibly all images)
!!  results_out(0:ndtset_alloc)=<type results_out_type>contains the results
!!   needed for outvars, including evolving variables
!!
!! OUTPUT
!!  Only writing
!!
!! NOTES
!! Note that this routine is called only by the processor me==0 .
!! In consequence, no use of message and wrtout routine.
!!
!! SOURCE

subroutine out_spg_anal(dtsets,echo_spgroup,iout,ndtset,ndtset_alloc,results_out)

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: echo_spgroup,iout
 integer,intent(in) :: ndtset,ndtset_alloc
!arrays
 type(dataset_type),intent(in) :: dtsets(0:ndtset_alloc)
 type(results_out_type),intent(in) :: results_out(0:ndtset_alloc)

!Local variables-------------------------------
!scalars
 integer, save :: counter0=1, counter1=1
 integer :: idtset,iimage,invar_z,jdtset,msym,mu,natom,nimage,nptsym,nsym
 integer :: ptgroupma,spgroup,symmetry_changed
 real(dp) :: tolsym,ucvol
 character(len=500) :: msg
!arrays
 integer :: bravais(11)
 integer, allocatable :: ptsymrel(:,:,:),symafm(:),symrel(:,:,:)
 real(dp) :: acell(3),genafm(3),gmet(3,3),gprimd(3,3),rmet(3,3),rprim(3,3),rprimd(3,3)
 real(dp), allocatable :: tnons(:,:)

! *************************************************************************

!An upper bound on the number of symmetry operations is 48 (maximum of point symmetries) times 2 (for the spin flip)
!times the number of atoms as the latter gives the maximum number of non-symmorphic translations.
!Actually, a better bound might be obtained from the minimum of the numbers of atoms of the same type,
!but this refinement is not needed here.
 msym=96*dtsets(1)%natom
 if(ndtset_alloc>1)then
   do idtset=2,ndtset_alloc
     msym=max(96*dtsets(idtset)%natom,msym)
   end do
 end if
 ABI_MALLOC(ptsymrel,(3,3,msym))
 ABI_MALLOC(symafm,(msym))
 ABI_MALLOC(symrel,(3,3,msym))
 ABI_MALLOC(tnons,(3,msym))

 do idtset=1,ndtset_alloc

   tolsym=dtsets(idtset)%tolsym
   natom=dtsets(idtset)%natom
   nimage=results_out(idtset)%nimage
   jdtset=dtsets(idtset)%jdtset ; if(ndtset==0)jdtset=0

   do iimage=1,nimage

     acell=results_out(idtset)%acell(:,iimage)
     rprim=results_out(idtset)%rprim(:,:,iimage)
     call mkrdim(acell,rprim,rprimd)
     call metric(gmet,gprimd,dev_null,rmet,rprimd,ucvol)

     !From rprimd and tolsym, compute bravais, nptsym and ptsymrel (with maximum size msym).
     call symlatt(bravais,dev_null,msym,nptsym,ptsymrel,rprimd,tolsym)

!DEBUG
!    write(std_out,*)' out_spg_data : before symfind_expert, return, msym=  ',msym
!     write(std_out,*)' out_spg_data : before symfind_expert, continue  '
!    return
!ENDDEBUG

     invar_z=0 ; if(dtsets(idtset)%jellslab/=0 .or. dtsets(idtset)%nzchempot/=0)invar_z=2

     call symfind_expert(gprimd,msym,natom,nptsym,dtsets(idtset)%nspden,nsym,&
       dtsets(idtset)%pawspnorb,dtsets(idtset)%prtvol,ptsymrel,dtsets(idtset)%spinat,symafm,symrel,&
       tnons,tolsym,dtsets(idtset)%typat,dtsets(idtset)%usepaw,results_out(idtset)%xred(1:3,1:natom,iimage),&
       chrgat=dtsets(idtset)%chrgat,nucdipmom=dtsets(idtset)%nucdipmom,&
       invardir_red=dtsets(idtset)%field_red,invar_z=invar_z)

!DEBUG
!    write(std_out,*)' out_spg_data : before symfind_expert, return  '
!    write(std_out,*)' out_spg_data : after symfind_expert, return  '
!    return
!ENDDEBUG

     !Set chkprim to 0, to allow detecting increase of multiplicity
     call symanal(bravais,0,genafm,msym,nsym,ptgroupma,rprimd,spgroup,symafm,symrel,tnons,tolsym)

     symmetry_changed=0
     if( nsym/=dtsets(idtset)%nsym .or. spgroup/=dtsets(idtset)%spgroup .or. &
&        ptgroupma/=dtsets(idtset)%ptgroupma)then
       symmetry_changed=1
     endif

!DEBUG
!    write(std_out,*)' m_out_spg_anal : determined symmetry_changed =', symmetry_changed
!    write(std_out,*)' m_out_spg_anal : nsym, dtsets(idtset)%nsym=',nsym, dtsets(idtset)%nsym
!    write(std_out,*)' m_out_spg_anal : spgroup,dtsets(idtset)%spgroup=',spgroup,dtsets(idtset)%spgroup
!    write(std_out,*)' m_out_spg_anal : ptgroupma,dtsets(idtset)%ptgroupma=',ptgroupma,dtsets(idtset)%ptgroupma
!ENDDEBUG

     if(symmetry_changed==1)then
       if(counter0==1)then
         write(msg,'(8a)')ch10,' The spacegroup number, the magnetic point group, and/or the number of symmetries',ch10,&
&         ' have changed between the initial recognition based on the input file',ch10,&
&         ' and a postprocessing based on the final acell, rprim, and xred.',ch10,&
&         ' More details in the log file.'
         call wrtout(iout,msg)
         counter0=0
       endif
       if(echo_spgroup==1 .and. counter1==1)then
         write(msg,'(10a)')ch10,' The spacegroup number, the magnetic point group, and/or the number of symmetries',ch10,&
&         ' have changed between the initial recognition based on the input file',ch10,&
&         ' and a postprocessing based on the final acell, rprim, and xred.',ch10,&
&         ' These modifications are detailed below.',ch10,&
&         ' The updated tnons, symrel or symrel have NOT been reported in the final echo of variables after computation.'
         call wrtout(std_out,msg)
         write(msg,'(5a)')' Such change of spacegroup, or magnetic point group might happen in several cases.',ch10,&
&         ' (1) If spgroup (+ptgroupma) defined in the input file, but the actual groups are supergroups of these; ',ch10,&
&         ' (2) If symrel, tnons (+symafm) defined in the input file, while the system is more symmetric; '
         call wrtout(std_out,msg)
         write(msg,'(5a)')&
&         ' (3) If the geometry has been optimized and the final structure is more symmetric than the initial one;',ch10,&
&         ' (4) In case of GW of BSE calculation with inversion symmetry, as nsym has been reduced in such',ch10,&
&         '       dataset, excluding the improper symmetry operations (with determinant=-1), but not in the postprocessing.'
         call wrtout(std_out,msg)
         write(msg,'(5a)')' In some case, the recognition of symmetries strongly depends on the value of tolsym.',ch10,&
          ' You might investigate its effect by restarting abinit based on the final acell, rprim and xred,',ch10,&
&         ' and different values for tolsym.'
         counter1=0
       endif
     endif

!    Echo the spacegroup (and ptgroupma) if requested, and give more information if the symmetry changed.
     if(echo_spgroup==1)then

       if(symmetry_changed==0)then
         if(nimage==1)then
           call prtspgroup(bravais,genafm,std_out,jdtset,ptgroupma,spgroup)
         else
           call prtspgroup(bravais,genafm,std_out,jdtset,ptgroupma,spgroup,iimage=iimage)
         endif
       else
         write(msg,'(2a,3i8)')ch10,' Initial data. jdtset, iimage, nsym=',jdtset,iimage,dtsets(idtset)%nsym
         call wrtout(std_out,msg)
         if(nimage==1)then
           call prtspgroup(dtsets(idtset)%bravais,dtsets(idtset)%genafm,std_out,jdtset,&
&           dtsets(idtset)%ptgroupma,dtsets(idtset)%spgroup)
         else
           call prtspgroup(dtsets(idtset)%bravais,dtsets(idtset)%genafm,std_out,jdtset,&
&           dtsets(idtset)%ptgroupma,dtsets(idtset)%spgroup,iimage=iimage)
         endif
         write(msg,'(a,3i8)')' Final data.   jdtset, iimage, nsym=',jdtset,iimage,nsym
         call wrtout(std_out,msg)
         if(nimage==1)then
           call prtspgroup(bravais,genafm,std_out,jdtset,ptgroupma,spgroup)
         else
           call prtspgroup(bravais,genafm,std_out,jdtset,ptgroupma,spgroup,iimage=iimage)
         endif
       endif

     end if ! echo_spgroup==1

   enddo ! iimage

 enddo ! idtset

!###########################################################
!## Deallocations and cleaning

 ABI_FREE(ptsymrel)
 ABI_FREE(symafm)
 ABI_FREE(symrel)
 ABI_FREE(tnons)

 if(echo_spgroup==1)then
   write(msg,'(a,80a)')ch10,('=',mu=1,80)
   call wrtout(std_out,msg)
 endif

!**************************************************************************

end subroutine out_spg_anal
!!***

end module m_out_spg_anal
!!***
