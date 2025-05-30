!!****p* ABINIT/vdw_kernelgen
!! NAME
!!  vdw_kernelgen
!!
!! FUNCTION
!!  Generates vdW-DF kernels from the user input.
!!
!! COPYRIGHT
!!  Copyright (C) 2011-2025 ABINIT group (Yann Pouillon)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt.
!!  For the initials of contributors, see
!!  ~abinit/doc/developers/contributors.txt.
!!
!! INPUTS
!!  (main routine)
!!
!! OUTPUT
!!  (main routine)
!!
!! NOTES
!!  The input data must be provided in a pre-defined order and contain all
!!  adjustable parameters related to the generation of vdW-DF kernels.
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

program vdw_kernelgen

 use defs_basis
 use defs_abitypes
 use m_errors
 use m_xc_vdw
 use m_mpinfo
 use m_xmpi


#if defined HAVE_MPI2
 use mpi
#endif

 use m_build_info,   only : abinit_version
 use m_specialmsg,   only : specialmsg_getcount, herald
 use m_io_tools,     only : flush_unit

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments -----------------------------------

!Local variables-------------------------------
!no_abirules
!
 character(len=500) :: message
 
 type(MPI_type) :: mpi_enreg,mpi_enreg_seq
#if defined DEV_YP_VDWXC
 character(len=24) :: codename
 type(xc_vdw_type) :: vdw_params
 character(len=fnlen) :: vdw_filnam
#endif

!******************************************************************
!BEGIN EXECUTABLE SECTION

!Change communicator for I/O (mandatory!)
 call abi_io_redirect(new_io_comm=xmpi_world)
!Initialize MPI : one should write a separate routine -init_mpi_enreg-
!for doing that !!
 call xmpi_init()

!Default for sequential use
 call initmpi_seq(mpi_enreg)

!Signal MPI I/O compilation has been activated
#if defined HAVE_MPI_IO
 if(xmpi_paral==0)then
   write(message,'(3a)') &
&   '  In order to use MPI_IO, you must compile with the MPI flag ',ch10,&
&   '  Action : recompile your code with different CPP flags.'
   ABI_ERROR(message)
 end if
#endif

!Initialize memory profiling if it is activated
!if a full abimem.mocc report is desired, set the argument of abimem_init to "2" instead of "0"
!note that abimem.mocc files can easily be multiple GB in size so don't use this option normally
#ifdef HAVE_MEM_PROFILING
 call abimem_init(0)
#endif

!Other values of mpi_enreg are dataset dependent, and should NOT be initialized
!inside vdw_kernelgen.F90.

!* Init fake MPI type with values for sequential case.
 call initmpi_seq(MPI_enreg_seq)


#if defined DEV_YP_VDWXC

!=== Write greetings ===
 codename='vdW_KernelGen'//repeat(' ',11)
 call herald(codename,abinit_version,std_out)
!YP: calling dump_config() makes tests fail => commented
!call dump_config(std_out)

!**********************************************************************

!IMPORTANT: DO NOT TOUCH THE COMMENTS OF THE FOLLOWING BLOCK

!Read input parameters
!%%% VDW-DF: BEGIN INPUT PARAMS %%%
 read(*,*) vdw_params%functional
 read(*,*) vdw_params%zab
 read(*,*) vdw_params%ndpts
 read(*,*) vdw_params%dcut
 read(*,*) vdw_params%dratio
 read(*,*) vdw_params%dsoft
 read(*,*) vdw_params%phisoft
 read(*,*) vdw_params%nqpts
 read(*,*) vdw_params%qcut
 read(*,*) vdw_params%qratio
 read(*,*) vdw_params%nrpts
 read(*,*) vdw_params%rcut
 read(*,*) vdw_params%rsoft
 read(*,*) vdw_params%ngpts
 read(*,*) vdw_params%gcut
 read(*,*) vdw_params%acutmin
 read(*,*) vdw_params%aratio
 read(*,*) vdw_params%damax
 read(*,*) vdw_params%damin
 read(*,*) vdw_params%nsmooth
 read(*,*) vdw_params%tolerance
 read(*,*) vdw_params%tweaks
!%%% VDW-DF: END INPUT PARAMS %%%

 vdw_filnam = repeat(' ',fnlen)
 read(*,'(a)') vdw_filnam

 call xc_vdw_show(std_out,vdw_params)
 call xc_vdw_init(vdw_params)
 call xc_vdw_get_params(vdw_params)
 call xc_vdw_show(std_out,vdw_params)
 call xc_vdw_memcheck(std_out,vdw_params)
 call xc_vdw_write(trim(vdw_filnam)//'.nc')
 call xc_vdw_done(vdw_params)

!**********************************************************************

 write(message,'(a,a,a)') ch10, &
& '+vdw_kernelgen : the run completed successfully ', &
& ch10
 call wrtout(std_out,message,'COLL')
 call flush_unit(std_out)

 call destroy_mpi_enreg(mpi_enreg)

 call abinit_doctor("__vdw_kernelgen")

 call xmpi_end()

#else
 write(message,'(3a)') ch10,'vdW-DF functionals are not fully operational yet.',ch10
 ABI_ERROR(message)
#endif

 end program vdw_kernelgen
!!***
