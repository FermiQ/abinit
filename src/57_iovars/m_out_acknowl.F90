!!****m* ABINIT/m_out_acknowl
!! NAME
!!  m_out_acknowl
!!
!! FUNCTION
!! Echo acknowledgments for the ABINIT code.
!!
!! COPYRIGHT
!!  Copyright (C) 2008-2025 ABINIT group (XG)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

module m_out_acknowl

 use defs_basis
 use m_abicore
 use m_dtset

 use m_fstrings,     only : prep_char
 use defs_datatypes, only : pspheader_type

 implicit none

 private
!!***

 public :: out_acknowl
!!***

contains
!!***

!!****f* m_out_acknowl/out_acknowl
!! NAME
!! out_acknowl
!!
!! FUNCTION
!! Echo acknowledgments for the ABINIT code.
!!
!! INPUTS
!!  iout=unit number for echoed output
!!  dtsets(0:ndtset_alloc)=<type datafiles_type>contains all input variables
!!  ndtset_alloc=number of datasets, corrected for allocation of at least
!!   one data set. Use for most dimensioned arrays.
!!  npsp=number of pseudopotentials
!!  pspheads(npsp)=<type pspheader_type>=all the important information from the
!!   pseudopotential file headers, as well as the psp file names
!!
!! OUTPUT
!!  Only writing
!!
!! SOURCE

subroutine out_acknowl(dtsets,iout,ndtset_alloc,npsp,pspheads)

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: iout,npsp,ndtset_alloc
 type(pspheader_type),intent(in) :: pspheads(npsp)
!arrays
 type(dataset_type),intent(in) :: dtsets(0:ndtset_alloc)

!Local variables-------------------------------
 integer :: idtset,iprior,iref,ncited,nrefs,ipsp,print_optional
 integer, allocatable :: cite(:),priority(:)
 character(len=750), allocatable :: ref(:)
 character(len=600), allocatable :: comment(:)
 character(len=600+750) :: string

! *************************************************************************

!Allocate and initialize, for each possible reference, the flag for citation,
!the priority of the citation, the reference, and the comment.
 nrefs=46
 ABI_MALLOC(cite,(nrefs))
 ABI_MALLOC(ref,(nrefs))
 ABI_MALLOC(comment,(nrefs))

!Array to specify the priority
 ABI_MALLOC(priority,(nrefs))
!The highest, the best, except that one from -1 and -2 should be cited.
!0 means, cite if there are less than five papers total, otherwise forget, and any case, mention that it is optional.
!1-19 means specific papers, that must be cited. However, they might not appear in the top list of papers.
!20 means papers that should appear in the top list (usually, the most specific papers).

 ref(:)=' '
 comment(:)=' '
 cite(:)=0
 priority(:)=0

 ref(1)=' The Abinit project: Impact, environment and recent developments.'//ch10//&
   ' Computer Phys. Comm. 248, 107042 (2020).'//ch10//&
   ' X.Gonze, B. Amadon, G. Antonius, F.Arnardi, L.Baguet, J.-M.Beuken,'//ch10//&
   ' J.Bieder, F.Bottin, J.Bouchet, E.Bousquet, N.Brouwer, F.Bruneval,'//ch10//&
   ' G.Brunin, T.Cavignac, J.-B. Charraud, Wei Chen, M.Cote, S.Cottenier,'//ch10//&
   ' J.Denier, G.Geneste, Ph.Ghosez, M.Giantomassi, Y.Gillet, O.Gingras,'//ch10
 ref(1)=trim(ref(1))//&
   ' D.R.Hamann, G.Hautier, Xu He, N.Helbig, N.Holzwarth, Y.Jia, F.Jollet,'//ch10//&
   ' W.Lafargue-Dit-Hauret, K.Lejaeghere, M.A.L.Marques, A.Martin, C.Martins,'//ch10//&
   ' H.P.C. Miranda, F.Naccarato, K. Persson, G.Petretto, V.Planes, Y.Pouillon,'//ch10//&
   ' S.Prokhorenko, F.Ricci, G.-M.Rignanese, A.H.Romero, M.M.Schmitt, M.Torrent,'//ch10//&
   ' M.J.van Setten, B.Van Troeye, M.J.Verstraete, G.Zerah and J.W.Zwanziger.'
 comment(1)=' Comment: the fifth generic paper describing the ABINIT project.'//ch10//&
   ' Note that a version of this paper, that is not formatted for Computer Phys. Comm. '//ch10//&
   ' is available at https://www.abinit.org/sites/default/files/ABINIT20.pdf .'//ch10//&
   ' The licence allows the authors to put it on the Web.'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze2020'
 priority(1)=3

 ref(2)=' ABINIT: Overview, and focus on selected capabilities'//ch10//&
   ' J. Chem. Phys. 152, 124102 (2020).'//ch10//&
   ' A. Romero, D.C. Allan, B. Amadon, G. Antonius, T. Applencourt, L.Baguet,'//ch10//&
   ' J.Bieder, F.Bottin, J.Bouchet, E.Bousquet, F.Bruneval,'//ch10//&
   ' G.Brunin, D.Caliste, M.Cote,'//ch10//&
   ' J.Denier, C. Dreyer, Ph.Ghosez, M.Giantomassi, Y.Gillet, O.Gingras,'//ch10
 ref(2)=trim(ref(2))//&
   ' D.R.Hamann, G.Hautier, F.Jollet, G. Jomard,'//ch10//&
   ' A.Martin, '//ch10//&
   ' H.P.C. Miranda, F.Naccarato, G.Petretto, N.A. Pike, V.Planes,'//ch10//&
   ' S.Prokhorenko, T. Rangel, F.Ricci, G.-M.Rignanese, M.Royo, M.Stengel, M.Torrent,'//ch10//&
   ' M.J.van Setten, B.Van Troeye, M.J.Verstraete, J.Wiktor, J.W.Zwanziger, and X.Gonze.'
 comment(2)=' Comment: a global overview of ABINIT, with focus on selected capabilities .'//ch10//&
   ' Note that a version of this paper, that is not formatted for J. Chem. Phys '//ch10//&
   ' is available at https://www.abinit.org/sites/default/files/ABINIT20_JPC.pdf .'//ch10//&
   ' The licence allows the authors to put it on the Web.'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#romero2020'
 priority(2)=2


 ref(3)=' Recent developments in the ABINIT software package.'//ch10//&
   ' Computer Phys. Comm. 205, 106 (2016).'//ch10//&
   ' X.Gonze, F.Jollet, F.Abreu Araujo, D.Adams, B.Amadon, T.Applencourt,'//ch10//&
   ' C.Audouze, J.-M.Beuken, J.Bieder, A.Bokhanchuk, E.Bousquet, F.Bruneval'//ch10//&
   ' D.Caliste, M.Cote, F.Dahm, F.Da Pieve, M.Delaveau, M.Di Gennaro,'//ch10//&
   ' B.Dorado, C.Espejo, G.Geneste, L.Genovese, A.Gerossier, M.Giantomassi,'//ch10//&
   ' Y.Gillet, D.R.Hamann, L.He, G.Jomard, J.Laflamme Janssen, S.Le Roux,'//ch10//&
   ' A.Levitt, A.Lherbier, F.Liu, I.Lukacevic, A.Martin, C.Martins,'//ch10
 ref(3)=trim(ref(3))//&
   ' M.J.T.Oliveira, S.Ponce, Y.Pouillon, T.Rangel, G.-M.Rignanese,'//ch10//&
   ' A.H.Romero, B.Rousseau, O.Rubel, A.A.Shukri, M.Stankovski, M.Torrent,'//ch10//&
   ' M.J.Van Setten, B.Van Troeye, M.J.Verstraete, D.Waroquier, J.Wiktor,'//ch10//&
   ' B.Xu, A.Zhou, J.W.Zwanziger.'
 comment(3)=' Comment: the fourth generic paper describing the ABINIT project.'//ch10//&
   ' Note that a version of this paper, that is not formatted for Computer Phys. Comm. '//ch10//&
   ' is available at https://www.abinit.org/sites/default/files/ABINIT16.pdf .'//ch10//&
   ' The licence allows the authors to put it on the Web.'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze2016'
 priority(3)=1

 ref(4)=' ABINIT: First-principles approach of materials and nanosystem properties.'//ch10//&
   ' Computer Phys. Comm. 180, 2582-2615 (2009).'//ch10//&
   ' X. Gonze, B. Amadon, P.-M. Anglade, J.-M. Beuken, F. Bottin, P. Boulanger, F. Bruneval,'//ch10//&
   ' D. Caliste, R. Caracas, M. Cote, T. Deutsch, L. Genovese, Ph. Ghosez, M. Giantomassi'//ch10//&
   ' S. Goedecker, D.R. Hamann, P. Hermet, F. Jollet, G. Jomard, S. Leroux, M. Mancini, S. Mazevet,'//ch10//&
   ' M.J.T. Oliveira, G. Onida, Y. Pouillon, T. Rangel, G.-M. Rignanese, D. Sangalli, R. Shaltaf,'//ch10//&
   ' M. Torrent, M.J. Verstraete, G. Zerah, J.W. Zwanziger'
 comment(4)=' Comment: the third generic paper describing the ABINIT project.'//ch10//&
   ' Note that a version of this paper, that is not formatted for Computer Phys. Comm. '//ch10//&
   ' is available at https://www.abinit.org/sites/default/files/ABINIT_CPC_v10.pdf .'//ch10//&
   ' The licence allows the authors to put it on the Web.'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze2009'
 priority(4)=0

 ref(5)=' A brief introduction to the ABINIT software package.'//ch10//&
   ' Z. Kristallogr. 220, 558-562 (2005).'//ch10//&
   ' X. Gonze, G.-M. Rignanese, M. Verstraete, J.-M. Beuken, Y. Pouillon, R. Caracas, F. Jollet,'//ch10//&
   ' M. Torrent, G. Zerah, M. Mikami, Ph. Ghosez, M. Veithen, J.-Y. Raty, V. Olevano, F. Bruneval,'//ch10//&
   ' L. Reining, R. Godby, G. Onida, D.R. Hamann, and D.C. Allan.'
 comment(5)=' Comment: the second generic paper describing the ABINIT project. Note that this paper'//ch10//&
   ' should be cited especially if you are using the GW part of ABINIT, as several authors'//ch10//&
   ' of this part are not in the list of authors of the first or third paper.'//ch10//&
   ' The .pdf of the latter paper is available at https://www.abinit.org/sites/default/files/zfk_0505-06_558-562.pdf.'//ch10//&
   ' Note that it should not redistributed (Copyright by Oldenburg Wissenschaftverlag,'//ch10//&
   ' the licence allows the authors to put it on the Web).'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze2005'
 priority(5)=0

 ref(6)=' First-principles computation of material properties: the ABINIT software project. '//ch10//&
   ' X. Gonze, J.-M. Beuken, R. Caracas, F. Detraux, M. Fuchs, G.-M. Rignanese, L. Sindic,'//ch10//&
   ' M. Verstraete, G. Zerah, F. Jollet, M. Torrent, A. Roy, M. Mikami, Ph. Ghosez, J.-Y. Raty, D.C. Allan.'//ch10//&
   ' Computational Materials Science 25, 478-492 (2002). http://dx.doi.org/10.1016/S0927-0256(02)00325-7'
 comment(6)=' Comment: the original paper describing the ABINIT project.'//ch10//&
   ' DOI and bibtex : see https://docs.abinit.org/theory/bibliography/#gonze2002'
 priority(6)=0

 ref(7)=' First-principles responses of solids to atomic displacements and homogeneous electric fields:,'//ch10//&
  ' implementation of a conjugate-gradient algorithm. X. Gonze, Phys. Rev. B55, 10337 (1997).'
 comment(7)=' Comment: Non-vanishing rfphon and/or rfelfd, in the norm-conserving case.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze1997'
 priority(7)=3

 ref(8)=' Dynamical matrices, Born effective charges, dielectric permittivity tensors, and ,'//ch10//&
  ' interatomic force constants from density-functional perturbation theory,'//ch10//&
  ' X. Gonze and C. Lee, Phys. Rev. B55, 10355 (1997).'
 comment(8)=' Comment: Non-vanishing rfphon and/or rfelfd, in the norm-conserving case.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze1997a'
 priority(8)=3

 ref(9)=' Metric tensor formulation of strain in density-functional perturbation theory, '//ch10//&
  ' D. R. Hamann, X. Wu, K. M. Rabe, and D. Vanderbilt, Phys. Rev. B71, 035117 (2005).'
 comment(9)=' Comment: Non-vanishing rfstrs. Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#hamann2005'
 priority(9)=18

 ref(10)=' Nonlinear optical susceptibilities, Raman efficiencies, and electrooptic tensors'//ch10//&
  ' from first principles density functional theory.'//ch10//&
  ' M. Veithen, X. Gonze, and Ph. Ghosez, Phys. Rev. B 71, 125107 (2005).'
 comment(10)=' Comment: to be cited for non-linear response calculations, with optdriver=5.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#veithen2005'
 priority(10)=20

 ref(11)=' Effect of self-consistency on quasiparticles in solids'//ch10//&
  ' F. Bruneval, N. Vast, L. Reining, Phys. Rev. B 74, 045102 (2006).'
 comment(11)=' Comment: in case gwcalctyp >= 10.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#bruneval2006'
 priority(11)=18

 ref(12)=' Accurate GW self-energies in a plane-wave basis using only a few empty states:'//ch10//&
  ' towards large systems. F. Bruneval, X. Gonze, Phys. Rev. B 78, 085125 (2008).'
 comment(12)=' Comment: to be cited for non-vanishing gwcomp. Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#bruneval2008'
 priority(12)=20

 ref(13)=' Large scale ab initio calculations based on three levels of parallelization'//ch10//&
  ' F. Bottin, S. Leroux, A. Knyazev, G. Zerah, Comput. Mat. Science 42, 329, (2008).'
 comment(13)=' Comment: in case LOBPCG algorithm is used (wfoptalg=4/14/114).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' This paper is also available at http://www.arxiv.org/abs/0707.3405'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#bottin2008'
 priority(13)=10

 ref(14)=' Implementation of the Projector Augmented-Wave Method in the ABINIT code.'//ch10//&
  ' M. Torrent, F. Jollet, F. Bottin, G. Zerah, and X. Gonze Comput. Mat. Science 42, 337, (2008).'
 comment(14)=' Comment: PAW calculations. Strong suggestion to cite this paper.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#torrent2008'
 priority(14)=15

 ref(15)=' Gamma and beta cerium: DFT+U calculations of ground-state parameters.'//ch10//&
  ' B. Amadon, F. Jollet and M. Torrent, Phys. Rev. B 77, 155104 (2008).'
 comment(15)=' Comment: DFT+U calculations, usepawu/=0. Strong suggestion to cite this paper.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#amadon2008a'
 priority(15)=18

 ref(16)=' Preconditioning of self-consistent-field cycles in density functional theory: the extrapolar method'//ch10//&
  ' P.-M. Anglade, X. Gonze, Phys. Rev. B 78, 045126 (2008).'
 comment(16)=' Comment: to be cited in case the extrapolar conditioner is used, i.e. non-vanishing iprcel.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#anglade2008'
 priority(16)=10

 ref(17)=' Specification of an extensible and portable file format for electronic structure and crystallographic data'//ch10//&
  ' X. Gonze, C.-O. Almbladh, A. Cucca, D. Caliste, C. Freysoldt, M. Marques, V. Olevano, Y. Pouillon, M.J. Verstraete,'//ch10//&
  ' Comput. Material Science 43, 1056 (2008).'
 comment(17)=' Comment: to be cited in case the ETSF_IO file format is used, i.e. iomode=3.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze2008'
 priority(17)=20

 ref(18)=' Daubechies wavelets as a basis set for density functional pseudopotential calculations.'//ch10//&
  ' L. Genovese, A. Neelov, S. Goedecker, T. Deutsch, S.A. Ghasemi, A. Willand,'// &
  ' D. Caliste, O. Zilberberg, M. Rayson, A. Bergman et R. Schneider,'//ch10//&
  ' J. Chem. Phys. 129, 014109 (2008).'
 comment(18)=' Comment: to be cited in case BigDFT project is used, i.e. usewvl=1.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#genovese2008'
 priority(18)=5

 ref(19)=' Calculations of the transport properties within the PAW formalism.'//ch10//&
  ' S. Mazevet, M. Torrent, V. Recoules, F. Jollet,'// &
  ' High Energy Density Physics, 6, 84-88 (2010).'
 comment(19)=' Comment: to be cited in case output for transport properties calculation within PAW is used,'//ch10//&
  '           i.e. prtnabla>0 and usepaw=1.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#genovese2008'
 priority(19)=20

 ref(20)=' Plane-wave based electronic structure calculations for correlated materials.'//ch10//&
  ' using dynamical mean-field theory and projected local orbitals,'//ch10// &
  ' B. Amadon, F. Lechermann, A. Georges, F. Jollet, T.O. Wehling, A.I. Lichenstein,'//ch10// &
  ' Phys. Rev. B 77, 205112 (2008).'
 comment(20)=' Comment: to be cited in case the computation of overlap operator'// &
   ' for Wannier90 interface within PAW is used,'//ch10//&
   ' i.e. prtwant=2 and usepaw=1. The paper describes also the DFT+DMFT implementation on Wannier functions'//ch10//&
   ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#amadon2008'
 priority(20)=19

 ref(21)=' First-principles calculation of electric field gradients in metals, semiconductors, and insulators.'//ch10//&
  ' J.W. Zwanziger, M. Torrent,'// &
  ' Applied Magnetic Resonance 33, 447-456 (2008).'
 comment(21)=&
  ' Comment: to be cited in case the computation of electric field gradient is used, i.e. nucefg>0 and usepaw=1.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#zwanziger2008'
 priority(21)=20

 ref(22)=' Computation of Moessbauer isomer shifts from first principles.'//ch10//&
  ' J.W. Zwanziger, '// &
  ' J. Phys. Conden. Matt. 21, 15024-15036 (2009).'
 comment(22)=' Comment: to be cited in case the computation of Fermi contact'// &
  ' interactions for isomer shifts, i.e. nucfc=1 and usepaw=1.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#zwanziger2009'
 priority(22)=20

 ref(23)=' Projector augmented-wave approach to density-functional perturbation theory.'//ch10//&
  ' C. Audouze, F. Jollet, M. Torrent and X. Gonze,'// &
  ' Phys. Rev. B 73, 235101 (2006).'//ch10// &
  ' Comparison between projector augmented-wave and ultrasoft pseudopotential formalisms'//ch10//&
  ' at the density-functional perturbation theory level.'//ch10//&
  ' C. Audouze, F. Jollet, M. Torrent and X. Gonze,'// &
  ' Phys. Rev. B 78, 035105 (2008).'
 comment(23)=' Comment: to be cited in case the computation of response function'// &
  ' with PAW, i.e. (rfphon=1 or rfelfd=1) and usepaw=1.'//ch10// &
  ' Strong suggestion to cite these papers.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#audouze2006,'//ch10//&
  ' and https://docs.abinit.org/theory/bibliography/#audouze2008'
 priority(23)=16

 ref(24)=' Libxc: A library of exchange and correlation functionals for density functional theory.'//ch10//&
  ' M.A.L. Marques, M.J.T. Oliveira, T. Burnus,'// &
  ' Computer Physics Communications 183, 2227 (2012).'
 comment(24)=' Comment: to be cited when LibXC is used (negative value of ixc)'//ch10// &
  ' Strong suggestion to cite this paper.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#marques2012'
 priority(24)=12

 ref(25)=' A self-consistent DFT + DMFT scheme in the projector augmented wave method: '//ch10//&
  ' applications to cerium, Ce2O3 and Pu2O3 with the Hubbard I solver and comparison to DFT + U,'//ch10//&
  ' B. Amadon,'// &
  '  J. Phys.: Condens. Matter 24 075604 (2012).'
 comment(25)=' Comment : Describes the self-consistent implementation of DFT+DMFT in PAW'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#amadon2012'
 priority(25)=20

 ref(26)=' Screened Coulomb interaction calculations: cRPA implementation and applications '//ch10//&
  ' to dynamical screening and self-consistency in uranium dioxide and cerium'//ch10// &
  ' B. Amadon, T. Applencourt and F. Bruneval '// &
  ' Phys. Rev. B 89, 125110 (2014).'
 comment(26)=' Comment: Describes the cRPA implementation of the screened Coulomb interaction in PAW'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#amadon2014'
 priority(26)=20

 ref(27)= ' Optimized norm-conserving Vanderbilt pseudopotentials.'//ch10//&
  ' D.R. Hamann, Phys. Rev. B 88, 085117 (2013).'
 comment(27)=' Comment: Some pseudopotential generated using the ONCVPSP code were used.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#hamann2013'
 priority(27)=3

 ref(28)= ' Two-component density functional theory within the projector augmented-wave approach:'//ch10//&
  ' Accurate and self-consistent computations of positron lifetimes and momentum distributions'//ch10//&
  ' J. Wiktor, G. Jomard and M. Torrent, Phys. Rev. B 92, 125113 (2015).'
 comment(28)=' Comment: to be cited in case the computation of electron-positron'// &
  ' annihilation properties within the 2-component DFT, i.e. positron/=0.'//ch10// &
  ' Strong suggestion to cite this paper.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#wiktor2015'
 priority(28)=20

 ref(29)= ' Parallel eigensolvers in plane-wave Density Functional Theory'//ch10//&
  ' A. Levitt and M. Torrent, Computer Phys. Comm. 187, 98-105 (2015).'
 comment(29)=' Comment: in case Chebyshev Filtering algorithm is used (wfoptalg=1/111).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#levitt2015'
 priority(29)=16

 ref(30)= ' Interatomic force constants including the DFT-D dispersion contribution'//ch10//&
  ' B. Van Troeye, M. Torrent, and X. Gonze. Phys. Rev. B93, 144304 (2016)'
 comment(30)=' Comment: in case one of the Van der Waals DFT-D functionals are used with DFPT (dynamical matrices).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#vantroeye2016'
 priority(30)=20

 ref(31)= ' Efficient on-the-fly interpolation technique for Bethe-Salpeter calculations of optical spectra'//ch10//&
  ' Y. Gillet, M. Giantomassi, and X. Gonze. Computer Physics Communications 203, 83 (2016)'
 comment(31)=' Comment: in case an interpolation technique is combined with Haydock recursion.'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gillet2016'
 priority(31)=20

 ref(32)= ' Precise effective masses from density functional perturbation theory'//ch10//&
  ' J. Laflamme Janssen, Y. Gillet, S. Ponce, A. Martin, M. Torrent, and X. Gonze. Phys. Rev. B 93, 205147 (2016)'
 comment(32)=' Comment: in case the DFPT prediction of effective masses is used.'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#laflamme2016'
 priority(32)=20

 ref(33)= ' Efficient dielectric matrix calculations using the Lanczos algorithm for fast many-body G0W0 implementations'//ch10//&
  ' J. Laflamme Janssen, B. Rousseau and M. Cote. Phys. Rev. B 91, 125120 (2015)'
 comment(33)=' Comment: in case the Lanczos-Sternheimer approach to GW is used.'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#laflamme2015'
 priority(33)=20

 ref(34)= ' Verification of first-principles codes: Comparison of total energies, phonon frequencies,'//ch10//&
  ' electron--phonon coupling and zero-point motion correction to the gap between ABINIT and QE/Yambo'//ch10//&
  ' S. Ponce, G. Antonius, P. Boulanger, E. Cannuccia, A. Marini, M. Cote and X. Gonze.'//&
  ' Computational Material Science 83, 341 (2014)'
 comment(34)=&
  ' Comment: the temperature-dependence of the electronic structure is computed (or the zero-point renormalisation).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex : see https://docs.abinit.org/theory/bibliography/#ponce2014'
 priority(34)=20

 ref(35)= ' Temperature dependence of the electronic structure of semiconductors and insulators '//ch10//&
  ' S. Ponce, Y. Gillet, J. Laflamme Janssen, A. Marini, M. Verstraete and X. Gonze. J. Chem. Phys. 143, 102813 (2015)'
 comment(35)=&
  ' Comment: the temperature-dependence of the electronic structure is computed (or the zero-point renormalisation).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#ponce2015'
 priority(35)=20

 ref(36)= ' Accurate band gaps of extended systems via efficient vertex corrections in GW '//ch10//&
  ' Wei Chen and A. Pasquarello. Phys. Rev. B 92, 041115 (2015)'
 comment(36)=' Comment: in case the bootstrap kernel (gwgamma -4) is used in GW calculations.'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#chen2015'
 priority(36)=20

 ref(37)= ' Projector augmented-wave formulation of response to strain and electric-field perturbation '//ch10//&
  ' within density functional perturbation theory '//ch10//&
  ' A. Martin, M. Torrent, and R. Caracas. Phys. Rev. B 99, 094112 (2019)'
 comment(37)=' Comment: in case Elastic constants, Born Effective charges, piezoelectric tensor '//ch10//&
  ' are computed within the Projector Augmented-Wave (PAW) approach. '//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#martin2019'
 priority(37)=20

 ref(38)=' Towards a potential-based conjugate gradient algorithm for order-N self-consistent'//ch10//&
   ' total energy calculations.'//ch10//&
   ' X. Gonze, Phys. Rev. B 54, 4383 (1996).'
 comment(38)=' Comment: The potential-based conjugate-gradient algorithm, used when iscf=5, is not published.'//ch10//&
  ' However, many elements of this algorithm have been explained in the paper above.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#gonze1996'
 priority(38)=0

 ref(39)=' Ab initio pseudopotentials for electronic structure calculations of poly-atomic systems, '//ch10//&
  ' using density-functional theory.'//ch10//&
  ' M. Fuchs and, M. Scheffler, Comput. Phys. Commun. 119, 67 (1999).'
 comment(39)=' Comment: Some pseudopotential generated using the FHI code were used.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#fuchs1999'
 priority(39)=3

 ref(40)=' First-Principles Theory of Spatial Dispersion: Dynamical Quadrupoles and Flexoelectricity, '//ch10//&
  ' M. Royo and M. Stengel, Phys. Rev. X 9, 021050 (2019).'
 comment(40)=' Comment : Flexoelectricity (see lw_flexo) or dynamical quadrupoles (see lw_qdrpl) have been computed.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#royo2019'
 priority(40)=20

 ref(41)=' Phonon-limited electron mobility in Si, GaAs, and GaP with exact treatment of dynamical quadrupoles, '//ch10//&
  ' G. Brunin, H. P. C. Miranda, M. Giantomassi, M. Royo, M. Stengel, M. J. Verstraete,'//ch10//&
  ' X. Gonze, G.-M. Rignanese and G. Hautier, Phys. Rev. B 102, 094308 (2020).'
 comment(41)=' Comment : Phonon-limited electron mobility has been computed using eph_task=7.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#brunin2020b'
 priority(41)=20

 ref(42)=' Predominance of non-adiabatic effects in zero-point renormalization of the electronic band gap,  '//ch10//&
  ' A. Miglio, V. Brousseau-Couture, E. Godbout, G. Antonius, Y.-H. Chan, S.G. Louie,  M. Cote, M. Giantomassi'//ch10//&
  ' and X. Gonze, npj Computational Materials 6, 167 (2020).'
 comment(42)=' Comment : Generalized Frohlich model calculations using eph_task=6.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#miglio2020'
 priority(42)=20

 ref(43)=' Photoinduced Phase Transitions in Ferroelectrics, '//ch10//&
  ' C. Paillard, E. Torun, L. Wirtz, J. Iniguez and L. Bellaiche, Phys. Rev. Lett. 123, 087601 (2019).'
 comment(43)=' Comment : Thermalized carriers eph_task=6.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#paillard2019'
 priority(43)=20

 ref(44)= ' Calculation of optical properties with spin-orbit coupling for warm dense matter'//ch10//&
  ' N. Brouwer and V. Recoules and N. Holzwarth and M. Torrent, Computer Phys. Comm. 266, 108029 (2021).'
 comment(44)=' Comment: Transport properties including spin-orbit coupling'//ch10//&
  ' within the PAW approach (prtnabla>0 and pawspnorb>0).'//ch10//&
  ' Strong suggestion to cite this paper in your publications.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#brouwer2021'
 priority(44)=20

 ref(45)=' Orbital magnetism and chemical shielding in the projector augmented-wave formalism.'//ch10//&
  ' J.W. Zwanziger, M. Torrent, and X. Gonze'// &
  ' Phys. Rev. B 107, 165157 (2023).'
 comment(45)=&
  ' Comment: to be cited in case the computation of orbital magnetism is used, i.e. orbmag>0.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#zwanziger2023'
 priority(45)=20

 ref(46)=' Facilities and practices for linear response Hubbard parameters U and J in Abinit.'//ch10//&
  " L. MacEnulty, M. Giantomassi, B. Amadon, G.-M. Rignanese and D.D. O'Regan"// &
  ' Electron. Struct. 6 037003 (2024).'
 comment(46)=&
  " Comment: to be cited in case the Hubbard U or Hund's J are calculated using the lrUJ utility"//ch10//&
  ' or the renovated functionalities of UJdet, i.e., macro_uj>0.'//ch10//&
  ' DOI and bibtex: see https://docs.abinit.org/theory/bibliography/#MacEnulty2024'
 priority(46)=20

 
 !---------------------------------------------------------------------------------------------
!Determine the papers to be cited

!Generic papers, not subject to conditions for citations
 cite(1:4)=1

!Go through the datasets
 do idtset=1,ndtset_alloc

!  If iscf=5 or iscf=15 used, cite Gonze96
   if(dtsets(idtset)%iscf==5)cite(6)=1
   if(dtsets(idtset)%iscf==15)cite(6)=1

!  If rfphon/=0 or rfelfd/=0, cite Gonze97a
   if(dtsets(idtset)%rfphon/=0)cite(7)=1
   if(dtsets(idtset)%rfelfd/=0)cite(7)=1

!  If rfphon/=0 or rfelfd/=0, cite Gonze97b
   if(dtsets(idtset)%rfphon/=0)cite(8)=1
   if(dtsets(idtset)%rfelfd/=0)cite(8)=1

!  If rfstrs/=0, cite Hamann05
   if(dtsets(idtset)%rfstrs/=0)cite(9)=1

!  If optdriver==5, cite Veithen2005
   if(dtsets(idtset)%optdriver==5)cite(10)=1

!  If gwcalctyp>=10, cite Bruneval2006
   if(dtsets(idtset)%gwcalctyp>=10)cite(11)=1

!  If gwcomp/=0, cite Bruneval2008
   if(dtsets(idtset)%gwcomp/=0)cite(12)=1

!  If paral_kgb/=0 and LOBPCG, cite Bottin2008
   if(dtsets(idtset)%paral_kgb/=0.and. &
&    (dtsets(idtset)%wfoptalg==4.or.dtsets(idtset)%wfoptalg==14.or.dtsets(idtset)%wfoptalg==114))cite(13)=1

!  If ucrpa/=0, cite Amadon2014
   if(dtsets(idtset)%ucrpa/=0) cite(26)=1

!  If usedmft/=0, cite Amadon2008b
   if(dtsets(idtset)%usedmft/=0)cite(20)=1

!  If usedmft/=0, cite Amadon2012
   if(dtsets(idtset)%usedmft/=0.and.dtsets(idtset)%nbandkss==0)cite(25)=1

!  If usepaw/=0, cite Torrent2008
   if(dtsets(idtset)%usepaw/=0)cite(14)=1

!  If usepawu/=0, cite Amadon2008
   if(dtsets(idtset)%usepawu/=0.and.dtsets(idtset)%usedmft==0) cite(15)=1

!  If iprcel/=0, cite Anglade2008
   if(dtsets(idtset)%iprcel/=0)cite(16)=1

!  If iomode==IO_MODE_ETSF, cite Gonze2008
   if(dtsets(idtset)%iomode==IO_MODE_ETSF)cite(17)=1

!  If usewvl/=0, cite Genovese2008
   if(dtsets(idtset)%usewvl/=0)cite(18)=1

!  If prtnabla/=0, cite Mazevet2010
   if(dtsets(idtset)%usepaw==1.and.dtsets(idtset)%prtnabla>0)cite(19)=1

!  If prtnabla/=0, cite Amadon2008
   if(dtsets(idtset)%usepaw==1.and.dtsets(idtset)%prtwant==2)cite(20)=1

!  If nucefg/=0, cite Zwanziger2008
   if(dtsets(idtset)%usepaw==1.and.dtsets(idtset)%nucefg>0)cite(21)=1

!  If nucfc/=0, cite Zwanziger2009
   if(dtsets(idtset)%usepaw==1.and.dtsets(idtset)%nucfc>0)cite(22)=1

!  If optdriver==1 and usepaw==1, cite Audouze2006 and Audouze2008
   if(dtsets(idtset)%usepaw==1.and.dtsets(idtset)%optdriver==1)cite(23)=1

!  If orbmag/=0, cite Zwanziger2023
   if(dtsets(idtset)%orbmag>0)cite(45)=1

!  If ixc<0, cite Marques2012
   if(dtsets(idtset)%ixc<0 .or. dtsets(idtset)%gwcalctyp>=100)cite(24)=1

!  If positron/=0 + PAW, cite Wiktor2015
   if(dtsets(idtset)%positron/=0.and.dtsets(idtset)%usepaw==1)cite(28)=1

!  If Chebyshev filtering (wfoptalg=1/111), cite Levitt2015
   if(dtsets(idtset)%wfoptalg==1.or.dtsets(idtset)%wfoptalg==111)cite(29)=1

!  If vdw_xc==5, 6 or 7 and rfphon/=0 or rfstrs/=0, cite Van Troeye 2016
   if(dtsets(idtset)%vdw_xc >=5 .and. dtsets(idtset)%vdw_xc <8)then
     if(dtsets(idtset)%rfphon/=0)cite(30)=1
     if(dtsets(idtset)%rfstrs/=0)cite(30)=1
   end if

!  If BSE interpolation is used, cite Gillet2016
   if(dtsets(idtset)%bs_interp_mode/=0)cite(31)=1

!  If effective mass tensor calculation is turned on, cite Laflamme2016
   if(dtsets(idtset)%efmas/=0)cite(32)=1

!  If Lanczos-Sternheimer GW is used, cite Laflamme2015
   if(dtsets(idtset)%optdriver==RUNL_GWLS)cite(33)=1

!  If electron-phonon effect on electronic structure is computed, cite Ponce2014 and Ponce 2015
   if(dtsets(idtset)%ieig2rf/=0)cite(34)=1
   if(dtsets(idtset)%ieig2rf/=0)cite(35)=1

!  If bootstrap kernel is used with GW, cite Chen2015
   if (any(dtsets(idtset)%gwgamma == [-3,-4,-5,-6])) cite(36)=1

!  If rfstrs/=0 or rfelfd/=0 and PAW, cite Martin2019
   if(dtsets(idtset)%rfstrs/=0.and.dtsets(idtset)%usepaw==1) cite(37)=1
   if(dtsets(idtset)%rfelfd/=0.and.dtsets(idtset)%usepaw==1) cite(37)=1

!  If iscf=5 or iscf=15 used, cite Gonze96
   if(dtsets(idtset)%iscf==5)cite(38)=1
   if(dtsets(idtset)%iscf==15)cite(38)=1

!  If lw_flexo/=0 or lw_qdrpl/=0, cite Royo2020
   if(dtsets(idtset)%lw_flexo/=0)cite(40)=1
   if(dtsets(idtset)%lw_qdrpl/=0)cite(40)=1

!  If eph_task==7, cite Brunin2020b
   if(dtsets(idtset)%eph_task==7 )cite(41)=1

!  If eph_task==6, cite Miglio2020
   if(dtsets(idtset)%eph_task==6 )cite(42)=1

!  If occopt==9, cite Paillard2019
   if(dtsets(idtset)%occopt==9 )cite(43)=1

!  If prtnabla>0 and nspinor==, cite Brouwer2021
   if(dtsets(idtset)%prtnabla>0.and.dtsets(idtset)%nspinor==2.and.dtsets(idtset)%pawspnorb>0 )cite(44)=1

!  If macro_uj>0, cite MacEnulty2024
   if(dtsets(idtset)%macro_uj>0 )cite(46)=1

 end do

!Go through the pseudopotentials
 do ipsp=1,npsp

!  If FHI pseudopotential, cite Fuchs 1999
   if(pspheads(ipsp)%pspcod==6)cite(39)=1
!  If psp8, cite Hamann 2013
   if(pspheads(ipsp)%pspcod==8)cite(27)=1
 end do

!-------------------------------------------------------------------------------------------
!Assemble the acknowledgment notice

 write(iout, '(30a)' )ch10,&
  '================================================================================',ch10,ch10,&
  ' Suggested references for the acknowledgment of ABINIT usage.',ch10,ch10,&
  ' The users of ABINIT have little formal obligations with respect to the ABINIT group',ch10,&
  ' (those specified in the GNU General Public License, http://www.gnu.org/copyleft/gpl.txt).',ch10,&
  ' However, it is common practice in the scientific literature,',ch10,&
  ' to acknowledge the efforts of people that have made the research possible.',ch10,&
  ' In this spirit, please find below suggested citations of work written by ABINIT developers,',ch10,&
  ' corresponding to implementations inside of ABINIT that you have used in the present run.',ch10,&
  ' Note also that it will be of great value to readers of publications presenting these results,',ch10,&
  ' to read papers enabling them to understand the theoretical formalism and details',ch10,&
  ' of the ABINIT implementation.',ch10,&
  ' For information on why they are suggested, see also https://docs.abinit.org/theory/acknowledgments.'

 ncited=0
 print_optional=1

 do iprior=20,0,-1
   do iref=1,nrefs
     if(cite(iref)==1)then
       if(priority(iref)==iprior)then
         if(priority(iref)>0 .or. (priority(iref)==1 .and. ncited<5) .or. (priority(iref)==0 .and. ncited<5)) then
           ncited=ncited+1
           cite(iref)=0
           if(priority(iref)==0 .and. print_optional==1)then
             print_optional=0
             write(iout,'(3a)')"-",ch10,'- And optionally:'
           end if
           if(len_trim(comment(iref))/=0)then
             write(string, '(2a,i0,4a)')ch10,' [',ncited,']',trim(ref(iref)),ch10,trim(comment(iref))
             call wrtout(iout,trim(prep_char(string, "-")))
           else
             write(string, '(2a,i0,4a)')ch10,' [',ncited,']',trim(ref(iref))
             call wrtout(iout,trim(prep_char(string, "-")))
           end if
         end if
       end if
       if(priority(iref)==0 .and. ncited>=5)cite(iref)=0
     end if
   end do
 end do

!Cleaning
 ABI_FREE(cite)
 ABI_FREE(ref)
 ABI_FREE(comment)
 ABI_FREE(priority)

end subroutine out_acknowl
!!***

end module m_out_acknowl
!!***
