!!****m* ABINIT/m_spmat_ndcoo
!! NAME
!! m_spmat_ndcoo
!!
!! FUNCTION
!! This module contains the a NDCOO (n-dimensional coordinate) format of sparse matrix.
!! Datatypes:
!!  NDCOO_mat_t: ND COO matrix
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

module m_spmat_NDCOO
  use defs_basis
  use m_abicore
  use m_errors
  use m_xmpi
  use m_spmat_base
  use m_dynamic_array, only: int2d_array_type, real_array_type, int_array_type
  implicit none
  !!***
  private

  !-----------------------------------------------------------------------
  !> @brief NDCOO_mat_t : N-dimensional COO matrix type
  !     The matrix is stored in two arrays, one for the indices, and
  !     the other for the values.
  !     e.g. a 3D matrix (M) with nnz non-zero entries will have an
  !     (3,nnz) array as indices, and a (nnz) array value.
  !     Both the index array and the value array are dynamic, so entries
  !     can be appended.
  !     let M be a 4*5*6 matrix,
  !       M(1,2,3)=1.9, M(1,3,4)=2.4, M(...) =0
  !     We'll have
  !       ndim=3, nnz=2, mshape=[4,5,6]
  !       ind = [ 1 2 3,
  !               1 3 4 ]
  !       val = [1.9, 2.4]
  !       (ind and val are dynamic array.)
  !-----------------------------------------------------------------------
  type, public :: ndcoo_mat_t
     integer :: ndim=0                  ! number of dimensions
     integer :: nnz=0                   ! Number of (None-zero) entries.
     integer, allocatable :: mshape(:)  ! the shape of the matrix. len(mshape)=ndim.
     ! Note that it is not checked if the index by the shaped. If the shape for some
     ! dimension is unkown, it can be set to -1.
     type(int2d_array_type) :: ind      ! The index array
     type(real_array_type) :: val       ! The value array
     logical :: is_sorted = .False.     ! If the matrix is sorted by index
     logical :: is_unique = .False.     ! If the matrix is made unique (no entry could have same index).
     logical :: is_pair_grouped = .False. ! If the matrix entries are grouped by first two indices
     type(int_array_type) :: pair_1list ! first index of the pair
     type(int_array_type) :: pair_2list ! second index of the pair
     type(int_array_type) :: pair_startend ! start and end matrix index of each group

   contains
     procedure :: initialize
     procedure :: finalize
     procedure :: add_entry             ! add one entry
     procedure :: remove_zeros          ! remove entries which are (or close to ) zero
     procedure :: sort_indices          ! sort the matrix by indices
     procedure :: sum_duplicates        ! remove duplicate indices by adding them up
     procedure :: get_val_inz           ! get the z'th value.
     procedure :: get_ind_inz           ! get the z'th indices.
     procedure :: get_ind               ! get the indices for all in a dimension
     procedure :: group_by_1dim         ! group the matrix by first dimension
     procedure :: group_by_pair         ! group the matrix by first two dimensions
     procedure :: mv1vec                ! multiply vector, return NDCOO entity with one dimension less
     procedure :: mv2vec                ! multiply 2 vectors, return NDCOO entity with two dimensions less
     procedure :: vec_product2d         ! multiply 2d matrix with one vector, return vector
     procedure :: vec_product           ! multiply 3d matrix with two vectors, return vector
     procedure :: vec_product4d         ! multiply 4d matrix with three vectors
     !procedure :: print
  end type ndcoo_mat_t

  public:: test_ndcoo
contains

  !-------------------------------------------------------------------!
  ! ndcoo_mat_t initializer:
  ! Input:
  !  mshape: the shape of the N-dimension matrix. array(ndim)
  !-------------------------------------------------------------------!
  subroutine initialize(self, mshape)
    class(ndcoo_mat_t), intent(inout) :: self
    integer, intent(in) :: mshape(:)
    self%ndim=size(mshape)
    ABI_MALLOC(self%mshape, (self%ndim))
    self%mshape=mshape
    self%nnz=0
    self%is_sorted=.False.
    self%is_unique=.False.
    self%is_pair_grouped = .False.

  end subroutine initialize

  !-------------------------------------------------------------------!
  ! Finalizer of ndcoo_mat_t
  !-------------------------------------------------------------------!
  subroutine finalize(self)
    class(ndcoo_mat_t), intent(inout) :: self
    self%ndim=0
    self%nnz=0
    self%is_sorted=.False.
    self%is_unique=.False.
    if((self%is_pair_grouped)) then
      call self%pair_1list%finalize()
      call self%pair_2list%finalize()
      call self%pair_startend%finalize()
    endif
    self%is_pair_grouped = .False.

    if (allocated(self%mshape)) then
       ABI_FREE(self%mshape)
    endif
    call self%ind%finalize()
    call self%val%finalize()
  end subroutine finalize

  !-------------------------------------------------------------------!
  ! Add one entry to the ndcoo_mat_t
  ! Inputs:
  !   ind: indices of the matrix.
  !   val: value of matrix.
  ! Example:
  !  call m%add_entry([1,2,3], 0.5)
  !-------------------------------------------------------------------!
  subroutine add_entry(self, ind, val)
    class(ndcoo_mat_t), intent(inout) :: self
    integer, intent(in) :: ind(self%ndim)
    real(dp), intent(in) :: val
    self%nnz=self%nnz+1
    call self%ind%push(ind)
    call self%val%push(val)
    self%is_sorted=.False.
    self%is_unique=.False.
    self%is_pair_grouped=.False.
  end subroutine add_entry


  !-------------------------------------------------------------------!
  ! sort the entries by indices. (left to right)
  !-------------------------------------------------------------------!
  subroutine sort_indices(self)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp) :: tmp(self%nnz)
    integer :: reorder(self%nnz)
    if(self%is_sorted .or. self%nnz==0) return
    call self%ind%sort(order=reorder)
    tmp(:)=self%val%data(1:self%nnz)
    self%val%data(1:self%nnz)=tmp(reorder)
    self%is_sorted=.True.
  end subroutine sort_indices


  !-------------------------------------------------------------------!
  ! Remove zero entries in coo matrix.
  !  zero means abs(x)<eps
  !-------------------------------------------------------------------!
  subroutine remove_zeros(self, eps)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp), optional, intent(in) :: eps
    real(dp) :: eps1
    integer :: i, counter
    if (present(eps)) then
       eps1=eps
    else
       eps1=epsilon(1.0_dp)
    end if
    counter=0
    do i=1, self%nnz
       if (abs(self%val%data(i))> epsilon(1.0)) then
          counter=counter+1
          self%ind%data(:,counter) =self%ind%data(:, i)
          self%val%data(counter) = self%val%data(i)
       end if
    end do
    self%nnz=counter
    self%ind%size=counter
    self%val%size=counter
  end subroutine remove_zeros

  !-------------------------------------------------------------------!
  ! sum duplicate entries (also sort by indices)
  !-------------------------------------------------------------------!
  subroutine sum_duplicates(self)
    class(ndcoo_mat_t), intent(inout) :: self
    integer :: new_ind(self%ndim, self%nnz), i, counter
    real(dp) :: new_val(self%nnz)
    if (self%nnz==0) then
       self%is_unique=.True.
       return
    end if
    call self%remove_zeros()
    if (.not. self%is_sorted) then
       call self%sort_indices()
    end if
    counter=1
    new_ind(:, counter)= self%ind%data(:, 1)
    new_val(counter)=self%val%data(1)
    do i=2, self%nnz
       if (all(self%ind%data(:, i)==self%ind%data(:, i-1))) then
          new_val(counter)=new_val(counter)+self%val%data(i)
       else
          counter=counter+1
          new_ind(:, counter)= self%ind%data(:, i)
          new_val(counter)=self%val%data(i)
       end if
    end do
    self%nnz=counter
    self%ind%data(:,1:counter)=new_ind(:,1:counter)
    self%val%data(1:counter)=new_val(1:counter)
    self%ind%size=self%nnz
    self%val%size=self%nnz
    self%is_unique=.True.
  end subroutine sum_duplicates

  !-------------------------------------------------------------------!
  ! Get the i'th value of the matrix.
  !-------------------------------------------------------------------!
  function get_val_inz(self, i) result(v)
    class(ndcoo_mat_t), intent(inout) :: self
    integer, intent(in) :: i
    real(dp) :: v
    v= self%val%data(i)
  end function get_val_inz


  !-------------------------------------------------------------------!
  ! get all the indices for the ith entry
  ! Input:
  !  i: ith entry
  ! Return:
  !  a integer array of indices.
  !-------------------------------------------------------------------!
  function get_ind_inz(self, i) result(ind)
    class(ndcoo_mat_t), intent(inout) :: self
    integer, intent(in) :: i
    integer :: ind(self%ndim)
    ind(:)=self%ind%data(:,i)
  end function get_ind_inz

  !-------------------------------------------------------------------!
  ! Group the sparse matrix by the first dimension
  !> Output:
  !> ngroup: number of groups
  !> i1_list: list of 1st indices (array(ngroup))
  !> istartend: start and end of each group (array(ngroup+1))
  !>           The starts will be istartend(1:ngroup)
  !>           The ends will be istartend(2: ngroup+1)-1
  !-------------------------------------------------------------------!
  subroutine group_by_1dim(self, ngroup, i1_list, istartend)
    class(ndcoo_mat_t), intent(inout) :: self
    integer,            intent(inout) :: ngroup
    integer, allocatable, intent(inout) :: i1_list(:), istartend(:)

    integer :: i, ii
    type(int_array_type) :: j1, jstartend

    if (.not. (self%is_unique))  then
      call self%sum_duplicates()
    end if
    if (self%nnz<1) then
      ngroup=0
    else if (self%nnz==1) then
      i=1
      ii=self%ind%data(1,i)
      call j1%push(ii)
      call jstartend%push(1)
      call jstartend%push(2)
    else
      i=1
      ii=self%ind%data(1,i)
      call j1%push(ii)
      call jstartend%push(i)
      do i=2, self%nnz
        ii=self%ind%data(1,i)
        if(ii == self%ind%data(1, i-1)) then
          cycle
        else
          call j1%push(ii)
          call jstartend%push(i)
        end if
      end do
      call jstartend%push(self%nnz+1)
    end if
    ngroup=j1%size
    if(ngroup>0) then
      ABI_MALLOC(i1_list, (ngroup))
      ABI_MALLOC(istartend, (ngroup+1))
      i1_list(:)=j1%data(1: j1%size)
      istartend(:)=jstartend%data(1: jstartend%size)
    end if
    call j1%finalize()
    call jstartend%finalize()
  end subroutine group_by_1dim

  !-------------------------------------------------------------------!
  ! Group the sparse matrix by first two indices
  !> Output:
  !> ngroup: number of groups
  !> ilist: list of one index of the pair (array(ngroup))
  !> jlist: list of other index of the pair (array(ngroup))
  !> ijstartend: start and end of each group (array(ngroup+1))
  !>           The starts will be ijstartend(1:ngroup)
  !>           The ends will be ijstartend(2: ngroup+1)-1
  !-------------------------------------------------------------------!

  subroutine group_by_pair(self)
    class(ndcoo_mat_t), intent(inout) :: self

    integer :: i, ii, ij
!    type(int_array_type) :: i1, j1, startend

    if((self%is_pair_grouped)) return

    if (.not. (self%is_unique))  then
      call self%sum_duplicates()
    end if
    if (self%nnz<1) then

    else if (self%nnz==1) then
      i=1
      ii=self%ind%data(1,i)
      ij=self%ind%data(2,i)
      call self%pair_1list%push(ii)
      call self%pair_2list%push(ij)
      call self%pair_startend%push(1)
      call self%pair_startend%push(2)
    else
      i=1
      ii=self%ind%data(1,i)
      ij=self%ind%data(2,i)
      call self%pair_1list%push(ii)
      call self%pair_2list%push(ij)
      call self%pair_startend%push(i)
      do i=2, self%nnz
        ii=self%ind%data(1,i)
        ij=self%ind%data(2,i)
        if(ii == self%ind%data(1, i-1) .and. ij == self%ind%data(2, i-1)) then
          cycle
        else
          call self%pair_1list%push(ii)
          call self%pair_2list%push(ij)
          call self%pair_startend%push(i)
        end if
      end do
      call self%pair_startend%push(self%nnz+1)
    end if

    self%is_pair_grouped = .true.

  end subroutine group_by_pair


  !-------------------------------------------------------------------!
  ! Get the indices of the dim'th dimension
  ! Input:
  !   dim: dimension
  ! Returns:
  !   a integer array(nnz)
  !-------------------------------------------------------------------!
  function get_ind(self, dim) result(ilist)
    class(ndcoo_mat_t), intent(inout) :: self
    integer, intent(in) :: dim
    integer :: ilist(self%nnz)
    ilist(:)=self%ind%data(dim, 1:self%nnz)
  end function get_ind


  ! matrix vector product
  subroutine mv1vec(self, vec, iv, res)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp),           intent(in)    :: vec(:)
    integer,            intent(in)    :: iv  ! which index is used for multiplication
    class(ndcoo_mat_t), intent(inout) :: res ! result

    integer :: iind, iiv, j, jv
    integer :: ind(1:res%ndim)
    real(dp) :: val

    if(self%ndim .ne. res%ndim+1) then
      ABI_ERROR('Dimension of resulting matrix is not equal to (dimension of initial matrix -1)')
    endif

    do iind =1 , self%nnz
      iiv=self%ind%data(iv, iind)
      jv=0
      do j=1, self%ndim
        if(j.ne.iv) then
          jv=jv+1
          ind(jv) = self%ind%data(j, iind)
        endif
      enddo
      val = self%val%data(iind)*vec(iiv)
      call res%add_entry(ind, val)
    end do

    call sum_duplicates(res)

  end subroutine mv1vec


  subroutine mv2vec(self, veci, vecj, iv, jv, res)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp),           intent(in)    :: veci(:), vecj(:) ! vectors to be multiplied with
    integer,            intent(in)    :: iv, jv  ! which indices are used for multiplication
    class(ndcoo_mat_t), intent(inout) :: res ! result

    integer :: iind, iiv, ijv, jnew, j
    integer :: ind(1:res%ndim)
    real(dp) :: val

    if(self%ndim .ne. res%ndim+2) then
      ABI_ERROR('Dimension of resulting matrix is not equal to (dimension of initial matrix -2)')
    endif
    do iind =1 , self%nnz
      iiv=self%ind%data(iv, iind)
      ijv=self%ind%data(jv, iind)
      jnew=0
      do j=1, self%ndim
        if(j.ne.iv .and. j.ne.jv) then
          jnew=jnew+1
          ind(jnew) = self%ind%data(j, iind)
        endif
      enddo
      val = self%val%data(iind)*veci(iiv)*vecj(ijv)
      call res%add_entry(ind, val)
    end do
    call sum_duplicates(res)

  end subroutine mv2vec


  subroutine vec_product2d(self, iv, veci, rv, res)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp), intent(in) :: veci(:)
    integer ,intent(in) :: iv, rv               !
    real(dp), intent(inout) :: res(:)
    integer :: iind, iiv, irv
    do iind =1 , self%nnz
      iiv=self%ind%data(iv, iind)
      irv=self%ind%data(rv, iind)
      res(irv) = res(irv) + self%val%data(iind) * veci(iiv)
    end do
  end subroutine vec_product2d



  ! matrix vector vector  product. matrix should be dim3.
  ! n(vector)=ndim-1
  ! which returns a vecor
  ! res_r = \sum_ij M_{ijr} V_i V_j
  ! i, j, r can be in any order.
  subroutine vec_product(self, iv, veci, jv, vecj, rv, res)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp), intent(in) :: veci(:), vecj(:)
    integer ,intent(in) :: iv, jv, rv               !
    real(dp), intent(inout) :: res(:)
    integer :: iind, iiv, ijv, irv
    do iind =1 , self%nnz
      iiv=self%ind%data(iv, iind)
      ijv=self%ind%data(jv, iind)
      irv=self%ind%data(rv, iind)
      res(irv) = res(irv) + self%val%data(iind) * veci(iiv)*vecj(ijv)
    end do
  end subroutine vec_product


  ! matrix vector vector vector product. matrix should be dim4.
  ! n(vector)=ndim-1
  ! which returns a vecor
  ! res_r = \sum_ijk M_{ijkr} V_i V_j V_k
  ! i, j, k, r can be in any order.
  subroutine vec_product4d(self, veci, vecj, kv, veck, rv, res)
    class(ndcoo_mat_t), intent(inout) :: self
    real(dp), intent(in) :: veci(:), vecj(:), veck(:)
    integer ,intent(in) :: kv, rv
    real(dp), intent(inout) :: res(:)

    integer :: iind, iiv, ijv, ikv, irv, igroup, istart, iend
    real(dp) :: scalprod

    if(.not.(self%is_pair_grouped)) then
      call self%group_by_pair()
    endif

    do igroup = 1, self%pair_1list%size
      !precalculate scalar product of first and second columns for each group
      istart=self%pair_startend%data(igroup)
      iend=self%pair_startend%data(igroup+1)-1
      iiv=self%pair_1list%data(igroup)
      ijv=self%pair_2list%data(igroup)
      scalprod=veci(iiv)*vecj(ijv)
      do iind=istart, iend
        ikv=self%ind%data(kv, iind)
        irv=self%ind%data(rv, iind)
        res(irv) = res(irv) + self%val%data(iind) * veck(ikv)* scalprod
      end do
    enddo
  end subroutine vec_product4d



  subroutine test_ndcoo()
    type(ndcoo_mat_t) :: m
    integer :: ngroup
    integer, allocatable :: i1list(:), ise(:)
    call m%initialize(mshape=[3,3,3])
    call m%add_entry(ind=[3, 2,1], val=0.3d0)
    call m%add_entry(ind=[1, 2,1], val=0.3d0)
    call m%add_entry(ind=[1, 2,1], val=0.4d0)
    call m%add_entry(ind=[3, 2,1], val=0.5d0)
    call m%add_entry(ind=[1, 1,2], val=0.5d0)
    call m%add_entry(ind=[2,5,1], val=0.0d0)
    !call m%print()
    call m%sort_indices()
    call m%sum_duplicates()
    !print *, "After sum"
    !call m%print()
    !print *, "Grouping"
    call m%group_by_1dim(ngroup, i1list, ise)
    !print *,  "ngroup: ", ngroup
    !print *, "i1list: ", i1list
    !print *, "ise: ", ise
    ABI_SFREE(i1list)
    ABI_SFREE(ise)
  end subroutine test_ndcoo

end module m_spmat_NDCOO

