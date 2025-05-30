!!****m* ABINIT/m_rttddft_driver
!! NAME
!!  m_rttddft_driver
!!
!! FUNCTION
!!  Real-Time Time Dependent DFT (RT-TDDFT)
!!
!! COPYRIGHT
!!  Copyright (C) 2021-2025 ABINIT group (FB)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

module m_rttddft_driver

 use defs_basis
 use defs_abitypes,        only: MPI_type
 use defs_datatypes,       only: pseudopotential_type

 use m_dtfil,              only: datafiles_type
 use m_dtset,              only: dataset_type
 use m_errors,             only: msg_hndl
 use m_pawang,             only: pawang_type
 use m_pawrad,             only: pawrad_type
 use m_pawtab,             only: pawtab_type
 use m_rttddft_output,     only: rttddft_output
 use m_rttddft_tdks,       only: tdks_type
 use m_rttddft_propagate,  only: rttddft_propagate_ele
 use m_rttddft_properties, only: rttddft_calc_density, &
                               & rttddft_calc_etot
 use m_specialmsg,         only: wrtout
 use m_time,               only: cwtime

 implicit none

 private
!!***

 public :: rttddft
!!***

contains
!!***

!!****f* m_rttddft_driver/rttddft
!! NAME
!!  rttddft
!!
!! FUNCTION
!!  Primary routine for real-time TDDFT calculations.
!!  1) Initialization: create main tdks (Time-Dependent Kohn-Sham) object
!!    - intialize various important parameters
!!    - read intial KS orbitals in WFK file
!!    - compute initial density from KS orbitals
!!  2) Propagation loop (rttddft_propagate):
!!    for i = 1, ntime
!!       - propagate KS orbitals
!!       - propagate nuclei if requested (Erhenfest dynamics)
!!       - compute new density
!!       - Compute and print requested properties
!!  3) Final printout and finalize
!!
!! INPUTS
!!  codvsn = code version
!!  dtfil <type datafiles_type> = infos about file names
!!  dtset <type(dataset_type)> = all input variables for this dataset
!!  mpi_enreg <MPI_type> = MPI-parallelisation information
!!  pawang <type(pawang_type)> = paw angular mesh and related data
!!  pawrad(ntypat*usepaw) <type(pawrad_type)> = paw radial mesh and related data
!!  pawtab(ntypat*usepaw) <type(pawtab_type)> = paw tabulated starting data
!!  psps <type(pseudopotential_type)> = variables related to pseudopotentials
!!
!! OUTPUT
!!
!! SOURCE
subroutine rttddft(codvsn,dtfil,dtset,mpi_enreg,pawang,pawrad,pawtab,psps)

 implicit none

 !Arguments ------------------------------------
 !scalars
 character(len=8),           intent(in)    :: codvsn
 type(dataset_type),         intent(inout) :: dtset
 type(datafiles_type),       intent(inout) :: dtfil
 type(MPI_type),             intent(inout) :: mpi_enreg
 type(pawang_type),          intent(inout) :: pawang
 type(pseudopotential_type), intent(inout) :: psps
 !arrays
 type(pawrad_type), target,  intent(inout) :: pawrad(psps%ntypat*psps%usepaw)
 type(pawtab_type), target,  intent(inout) :: pawtab(psps%ntypat*psps%usepaw)

 !Local variables-------------------------------
 !scalars
 character(len=500)   :: msg
 integer              :: istep
 type(tdks_type)      :: tdks
 !arrays
 real(dp)             :: cpu, wall, gflops

! ***********************************************************************

 write(msg,'(7a)') ch10,'---------------------------------------------------------------------------',&
                 & ch10,'----------------   Starting real-time time dependent DFT   ----------------',&
                 & ch10,'---------------------------------------------------------------------------',ch10
 call wrtout(ab_out,msg)
 if (do_write_log) call wrtout(std_out,msg)

 !FB: Do not allow RT-TDDFT for now. Still under development
 write(msg,'(3a)') ch10,'Real-time time dependent DFT is not yet available. Still under development..',ch10
 call wrtout(ab_out,msg)
 if (do_write_log) call wrtout(std_out,msg)
 ABI_ERROR(msg)

 !** 1) Initialization: create main tdks (Time-Dependent Kohn-Sham) object
 write(msg,'(3a)') ch10,'---------------------------   Initialization   ----------------------------',ch10
 call wrtout(ab_out,msg)
 if (do_write_log) call wrtout(std_out,msg)

 call tdks%init(codvsn,dtfil,dtset,mpi_enreg,pawang,pawrad,pawtab,psps)

 !Compute initial electronic density
 call rttddft_calc_density(dtset,mpi_enreg,psps,tdks)

 !** 2) Propagation loop
 write(msg,'(3a)') ch10,'-------------------------   Starting propagation   ------------------------',ch10
 call wrtout(ab_out,msg)
 if (do_write_log) call wrtout(std_out,msg)
 
 do istep = tdks%first_step, tdks%first_step+tdks%ntime-1

   call cwtime(cpu, wall, gflops, "start")
 
   !Perform electronic step
   !Compute new WF at time t and energy contribution at time t-dt
   call rttddft_propagate_ele(dtset,istep,mpi_enreg,psps,tdks)

   !Compute total energy at time t-dt
   call rttddft_calc_etot(dtset,tdks%energies,tdks%etot,tdks%occ)

   !Compute new electronic density at t
   call rttddft_calc_density(dtset,mpi_enreg,psps,tdks)

   !Compute and output useful electronic values
   call rttddft_output(dtfil,dtset,istep,mpi_enreg,psps,tdks)

   !TODO: If Ehrenfest dynamics perform nuclear step
   !call rttddft_propagate_nuc(dtset,istep,mpi_enreg,psps,tdks)

   call cwtime(cpu,wall,gflops,"stop")
   write(msg,'(a,2f8.2,a)') 'Time - cpu, wall (sec):', cpu, wall, ch10
   call wrtout(ab_out,msg)
   if (do_write_log) call wrtout(std_out,msg)

 end do

 !** 3) Final Output and free memory
 write(msg,'(7a)') ch10,'---------------------------------------------------------------------------',&
                 & ch10,'----------------   Finished real-time time dependent DFT   ----------------',&
                 & ch10,'---------------------------------------------------------------------------',ch10
 call wrtout(ab_out,msg)
 if (do_write_log) call wrtout(std_out,msg)

 call tdks%free(dtset,mpi_enreg,psps)

end subroutine rttddft
!!***

end module m_rttddft_driver
!!***
