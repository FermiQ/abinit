!!****m* ABINIT/m_lattice_dummy_mover
!! NAME
!! m_lattice_dummy_mover
!!
!! FUNCTION
!! This module contains the dummy  lattice mover.
!! With this the lattice does not move. This is for test only.
!!
!! Datatypes:
!!
!! * lattice_dummy_mover_t: defines the lattice movers
!!
!! Subroutines:
!! TODO: add this when F2003 doc style is determined.
!!
!!
!! COPYRIGHT
!! Copyright (C) 2001-2025 ABINIT group (hexu)
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!! For the initials of contributors, see ~abinit/doc/developers/contributors.txt .
!!
!! SOURCE



#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

module m_lattice_dummy_mover
  use defs_basis
  use m_abicore
  use m_errors

  use m_multibinit_dataset, only: multibinit_dtset_type
  use m_abstract_potential, only: abstract_potential_t
  use m_abstract_mover, only: abstract_mover_t
  use m_lattice_mover, only: lattice_mover_t
  use m_multibinit_cell, only: mbcell_t, mbsupercell_t
  use m_random_xoroshiro128plus, only:  rng_t
  use m_hashtable_strval, only: hash_table_t
!!***

  implicit none

  private

  type, public, extends(lattice_mover_t) :: lattice_dummy_mover_t
   contains
     procedure :: initialize
     procedure :: finalize
     procedure :: run_one_step
  end type lattice_dummy_mover_t

contains


  subroutine initialize(self,params, supercell, rng)
    class(lattice_dummy_mover_t), intent(inout) :: self
    type(multibinit_dtset_type), target, intent(in):: params
    type(mbsupercell_t), target, intent(in) :: supercell
    type(rng_t), target, intent(in) :: rng
    call self%lattice_mover_t%initialize(params, supercell, rng)
    self%label = "Velocity Dummy lattice mover"
  end subroutine initialize

  subroutine finalize(self)
    class(lattice_dummy_mover_t), intent(inout) :: self
    call self%lattice_mover_t%finalize()
  end subroutine finalize


  !===================== run_one_step===============================!
  ! run one md step
  ! effpot: effective potential
  ! displacement: Should NOT be given, because it is stored in the mover already.
  ! strain: Should Not be given. Because 1) it is stored in the mover,
  !          and 2) this is a constant volume mover.
  ! spin: spin of atoms. Useful with spin-lattice coupling.
  ! lwf: lattice wannier function. Useful with lattice-lwf coupling (perhaps useless.)
  subroutine run_one_step(self, effpot,displacement, strain, spin, lwf, energy_table)
    class(lattice_dummy_mover_t), intent(inout) :: self
    class(abstract_potential_t), intent(inout) :: effpot
    real(dp), optional, intent(inout) :: displacement(:,:), strain(:,:), spin(:,:), lwf(:)
    type(hash_table_t), optional, intent(inout) :: energy_table
    integer :: i
    character(len=40) :: key


    self%forces(:, :) =0.0
    self%energy = 0.0
    call effpot%calculate( displacement=self%displacement, strain=self%strain, &
         & spin=spin, lwf=lwf, force=self%forces, stress=self%stress,  energy=self%energy, energy_table=energy_table)
    ! set velocity to zero.
    do i=1, self%natom
       !self%current_vcart(:,i) = self%current_vcart(:,i) + &
       !     & (0.5_dp * self%dt) * self%forces(:,i)/self%masses(i)
       self%current_vcart(:,i)=0.0
    end do

    !self%displacement(:,:) = self%displacement(:,:)+self%current_vcart(:,:) * self%dt
    
    call self%get_T_and_Ek()
    if (present(energy_table)) then
      key = 'Lattice kinetic energy'
       call energy_table%put(key, self%Ek)
    end if

    ABI_UNUSED_A(strain)
    ABI_UNUSED_A(displacement)
    ABI_UNUSED_A(energy_table)
  end subroutine run_one_step


end module m_lattice_dummy_mover

