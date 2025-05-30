---
authors: SP, MR, MS
---

# Dynamical quadrupoles with DFPT

This tutorial describes the computation of dynamical quadrupoles using
density functional perturbation theory (DFPT), using AlAs as an example.

It is assumed the user has already completed the two tutorials [RF1](/tutorial/rf1) and [RF2](/tutorial/rf2),
and is comfortable with the concepts of ground-state and response properties,
including phonons, Born effective charges and dielectric tensor.

The first-order terms in the long-wavelength expansion of a material's charge response to atomic displacements
are the Born effective charges (dynamical dipoles). The second-order terms in this expansion are known as
dynamical quadrupoles. Accordingly, the quadrupoles can be considered as the spatial-dispersion of the Born charges.

Dynamical quadrupoles can be used to go beyond the typical dipole approach to characterize the macroscopic,
long-range electrostatic fields generated by atomic displacements. This extension has been shown to be
important in the Fourier interpolation of several quantities, including: interatomic force constants [[cite:Royo2020]],
perturbed potentials [[cite:Brunin2020]], and electron-phonon matrix elements [[cite:Ponce2021]].

In addition, adaptations of these concepts exist for 2D materials in the context of interatomic force-constants [[cite:Royo2021]]
and electron-phonon matrices [[cite:Ponce2023]].

Completing this tutorial should take approximately 1 hour.

## Formalism

The general formalism to calculate spatial-dispersion properties from DFPT has been reported in [[cite:Royo2019]].
Therein, the dynamical quadrupoles can be calculated from the first ${\bf q}$-gradient of the second-order total energy
response due to an electric field and an atomic displacement:

\begin{equation}
Q_{\kappa\beta}^{(2,\gamma\delta)}= -2 i ( E_{\gamma}^{\mathcal{E}_\delta^* \tau_{\kappa\beta}}
 + E_{\delta}^{\mathcal{E}_\gamma^* \tau_{\kappa\beta}}),
\end{equation}

where $\kappa$ is a sublattice index and the rest of Greek indexes indicate Cartesian directions.
The first $\bf q$-gradient of the mixed energy due to an electric field and an atomic displacement is obtained as,

\begin{equation}
 E_{\gamma}^{\mathcal{E}_\delta^* \tau_{\kappa\beta}} = s \int_{\rm BZ} [d^3k] \sum_{m}
 E_{m{\bf k},\gamma}^{\mathcal{E}_\delta^* \tau_{\kappa\beta}}  +  \frac{1}{2} \int_{\Omega} \int K_{\gamma}({\bf r},{\bf r}') n^{\mathcal{E}_\delta} ({\bf r})
 n^{\tau_{\kappa\beta}}({\bf r}') d^3r d^3r',
\end{equation}

where $s=2$ is the spin multiplicity, $K_{\gamma}({\bf r},{\bf r}')$ is the $\bf q$-derivative of the Hartree and exchange-correlation kernel in the direction $\gamma$, and $n^\lambda$ is the first-order perturbed density due to a generic pertubation $\lambda$. The first term in the
above equation is a band-resolved contribution given by

\begin{equation}
  E_{m{\bf k},\gamma}^{\mathcal{E}_\delta^* \tau_{\kappa\beta}} =
 \langle u_{m{\bf k}}^{\mathcal{E}_{\delta}} | \partial_{\gamma} \hat{H}^{(0)}_{{\bf k}} | u_{m{\bf k}}^{\tau_{\kappa\beta}} \rangle + \langle u_{m{\bf k}}^{\mathcal{E}_{\delta}}| \partial_{\gamma} \hat{Q}_{{\bf k}}  \hat{\mathcal{H}}_{{\bf k}}^{\tau_{\kappa\beta}}  |
  u_{m{\bf k}}^{(0)} \rangle +
  \langle u_{m{\bf k}}^{(0)} |  V^{\mathcal{E}_{\delta}} \partial_{\gamma} \hat{Q}_{{\bf k}}| u_{m{\bf k}}^{\tau_{\kappa\beta}} \rangle + \langle  u_{m{\bf k}}^{\mathcal{E}_{\delta}}|  \hat{H}_{{\bf k},\gamma}^{\tau_{\kappa\beta}}  | u_{m{\bf k}}^{(0)} \rangle  +i  \langle u_{m{\bf k},\gamma}^{A_\delta}| u_{m{\bf k}}^{\tau_{\kappa\beta}} \rangle .
\end{equation}

where $\partial_{\gamma} \hat{H}^{(0)}_{{\bf k}}$ is the velocity operator; $\hat{\mathcal{H}}_{{\bf k}}^{\tau_{\kappa\beta}}$
and $\hat{H}_{{\bf k},\gamma}^{\tau_{\kappa\beta}}$ are, respectively, the atomic-displacement first-order Hamiltonian (the caligraphic symbol
indicates that self-consistent field potentials are included) and its gradient along $\gamma$; $V^{\mathcal{E}_{\delta}}$ is the first-order potential due to an electric field; and $\partial_{\gamma} \hat{Q}_{{\bf k}}$
is the gradient of the conduction-band projector. In addition, the above equation comprises a set of ground-state ($u_{m{\bf k}}^{(0)}$) and first-order wave functions.
Among the latter one finds the standard response functions due to an electric field ($u_{m{\bf k}}^{\mathcal{E}_{\delta}}$) and an atomic displacement ($u_{m{\bf k}}^{\tau_{\kappa\beta}}$), along with the response function due to a gradient of a vector potential ($u_{m{\bf k},\gamma}^{A_\delta}$). A discussion on how the latter
can be calculated from the auxiliary d2_dkdk second-order response functions (see [[rf2_dkdk]]) is provided in [[cite:Zabalo2022]].


[TUTORIAL_README]

## Quadrupole calculation in fcc AlAs

*Before beginning, you might consider creating a different subdirectory to work in.
Why not create Work_quad ?*

The file *tquad_1.abi* is the input file for the first step
(GS + DFPT perturbations for all the $\qq$-points in the IBZ).
Copy it to the working directory with:

```sh
cd $ABI_TESTS/tutorespfn/Input
mkdir Work_quad
cd Work_quad
cp ../tquad_1.abi .
```

{% dialog tests/tutorespfn/Input/tquad_1.abi %}

This step might be quite time-consuming so you may want to immediately start the job in background with:

```sh
abinit tquad_1.abi > tquad_1.log 2> err &
```

The logic behind this multi-dataset calculation is to sequentialy calculate the required
ingredients to be plugged in the quadrupole equations shown above. This involves:

* DS1: Perform ground-state calculation.
* DS2 and DS3: Perform ddk and d2_dkdk ([[rf2_dkdk]]=3 is mandatory) response function calculations.
* DS4: Perform response function calculations at **q** =Γ to atomic displacements and electric field,
including the option [[prepalw]]=2.
* DS5: Perform a longwave DFTP calculation of third-order energy derivatives ([[optdriver]]=10 and [[lw_qdrpl]]=1).

Upon finalization, open the output and look for the Quadrupole data block:

```sh
 Quadrupole tensor, in cartesian coordinates,
 efidir   atom   atdir    qgrdir          real part        imaginary part
    1       1       1       1           -0.0000000566        -0.0000000000
    1       1       2       1           -0.0000000157        -0.0000000000
    1       1       3       1            0.0000000157        -0.0000000000
    1       2       1       1           -0.0000001675        -0.0000000000
    1       2       2       1           -0.0000000042        -0.0000000000
    1       2       3       1            0.0000000042        -0.0000000000
    2       1       1       1           -0.0000000362        -0.0000000000
    2       1       2       1           -0.0000000205        -0.0000000000
    2       1       3       1           13.4866068621        -0.0000000000
    2       2       1       1           -0.0000000859        -0.0000000000
    2       2       2       1           -0.0000000816        -0.0000000000
    2       2       3       1           -6.0008872938        -0.0000000000
    3       1       1       1           -0.0000000362        -0.0000000000
    3       1       2       1           13.4866068621        -0.0000000000
    3       1       3       1           -0.0000000205        -0.0000000000
    3       2       1       1           -0.0000000859        -0.0000000000
    3       2       2       1           -6.0008872938        -0.0000000000
    3       2       3       1           -0.0000000816        -0.0000000000
```

Since we are in a binary FCC solid, there are only two independent quadrupoles values given by
$Q_{\kappa\beta}^{\gamma\delta} = Q_\kappa |\varepsilon_{\beta\gamma\delta}|$ where $\varepsilon_{\beta\gamma\delta}$ is the Levi-Cevita symbol.

In case you want to use the quadrupole tensor for the [EPW](https://epw-code.org/) code, you can use
the python convertor located in ```abinit/scripts/post_processing/ab2epw_quad.py```

{% dialog ../scripts/post_processing/ab2epw_quad.py %}


If you run the python code, the script will ask for the name of the output. Once provided you should obtain the following result:

```sh
  atom   dir       Qxx             Qyy         Qzz          Qyz            Qxz         Qxy
    1     1      0.00000000   0.00000000   0.00000000  13.48660685   0.00000000   0.00000000
    1     2      0.00000000   0.00000000   0.00000000   0.00000000  13.48660686   0.00000000
    1     3      0.00000000   0.00000000   0.00000000   0.00000000   0.00000000  13.48660686
    2     1      0.00000000   0.00000000   0.00000000  -6.00088730   0.00000000   0.00000000
    2     2      0.00000000   0.00000000   0.00000000   0.00000000  -6.00088729   0.00000000
    2     3      0.00000000   0.00000000   0.00000000   0.00000000   0.00000000  -6.00088729
```

which can be copied in a file name Quadrupole.fmt and used in EPW.
