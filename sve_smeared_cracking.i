#---- 2D smeared cracking study ----#

[GlobalParams]
  displacements = 'disp_x disp_y'
  large_kinematics = true

  # DO NOT DISABLE THIS
  stabilize_strain = true

[]

[Physics/SolidMechanics/QuasiStatic]
  [./all]
    strain = FINITE
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_xy'
  [../]
[]

# these are the unknowns in the PDE, only specifying x and y for 2D outputs
[Variables]
  [disp_x]
    family = lagrange
    order = second
  []
  [disp_y]
    family = lagrange
    order = second
  []

[]

# mesh

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 256
    ny = 256
    xmax = 1
    ymax = 1
    elem_type = QUAD8
                show_info=true
                output=true
  []
  [subdomain_id]
    type = SubdomainPerElementGenerator
    input = generated
    subdomain_ids = {{subdomain_ids}}
  []
  # defining node sets for PBCs and preventing rigid body motion
        [origin_set]
                type=ExtraNodesetGenerator
                new_boundary = 'origin'
                coord = '0 0'
                input=subdomain_id
        []
        [xp_set]
                type=ExtraNodesetGenerator
                new_boundary = 'x_plus'
                coord = '1 0'
                input=origin_set
        []
        [yp_set]
                type=ExtraNodesetGenerator
                new_boundary = 'y_plus'
                coord = '0 1'
                input=xp_set
        []

[]


# note: the shear modulus identified here is for the transverse direction.
# G_12 and G_13 would be the shear for the longitudinal direction.
# 11 is along the fibers (longitudinal dir)
# 22 is the x direction

#    ___________________
#   |                   |
#   |                   |
#   |                   |
#   |                   |
#   |                   |
#   |                   |
#   |                   |
#   |                   |      ^
#   |                   |   33 |
#   ---------------------      |___> 22



[Materials]
  # transverse isotropy
  [./elasticity_1]
    type = ComputeElasticityTensor
    # C_ijkl = '1111, 1122, 1133, 3333, 2323'
    C_ijkl = ' 8.25185e+09 4.39817e+09 4.16537e+09 8.88588e+10 1.90464e+09'
    fill_method = axisymmetric_rz
    block = 1
  [../]

  [./elasticity_0]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 3450000000.0
    poissons_ratio = 0.35
    block = 0
  [../]

  [./elastic_stress]
    type = ComputeSmearedCrackingStress
    cracking_stress = 3e6
    softening_models = abrupt_softening
  [../]
  [./abrupt_softening]
    type = AbruptSoftening
  [../]

[]

# load function
[Functions]
  [./displ]
    type = PiecewiseLinear
    # by default, x is time
    # apply 1 MPa until strain reaches 0.2, abrupt drop to zero
    x = '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18'
    y = '0 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 -0.2 0'
  [../]
[]

# PBCs and constraining rigid body motion
[BCs]
  [./Periodic]
    [./y]
      variable = disp_y
      auto_direction = 'x y'
    []
    [./x]
      variable = disp_x
      auto_direction = 'x y'
    []
  []
  # apply load
  [./pull]
    # type = FunctionNeumannBC
    type = FunctionDirichletBC
    boundary = "x_plus"
    variable = disp_x
    function = displ
  [../]
  # constrain rigid body motion by pinning the corners and origin
        [fix_origin_x]
                type = DirichletBC
                boundary = "origin"
                variable = disp_x
                value = 0
        []

        [fix_origin_y]
                type = DirichletBC
                boundary = "origin"
                variable = disp_y
                value = 0
        []

        [fix_x]
          type = DirichletBC
          boundary = "x_plus"
          variable = disp_x
          value = 0
        []

        [fix_y]
          type = DirichletBC
          boundary = "y_plus"
          variable = disp_y
          value = 0
        []
[]

[Executioner]
    type = Steady

    solve_type = 'pjfnk'
    line_search = 'bt'

    #petsc_options_iname = '-pc_type'
    #petsc_options_value = 'lu'

    petsc_options_iname = '-pc_type -pc_hypre_type -pc_hypre_boomeramg_strong_threshold'
    petsc_options_value = 'hypre     boomeramg      0.5'

    reuse_preconditioner = true
    reuse_preconditioner_max_linear_its = 10

    l_max_its = 100
    l_tol = 1e-10
    nl_max_its = 10

    # want to get 1e-8 accuracy everywhere
    nl_rel_tol = 1e-8
    # stress (divergence) up to 1e-8
    nl_abs_tol = 1e-8

    automatic_scaling = true
    # scale contributions from each disp var and imposed strain independently
    scaling_group_variables = 'disp_x ; disp_y; hvar'
[]


[Outputs]
  file_base = 'out_files/{{out_dir}}/{{base_name}}'
  exodus = true
  csv = true
[]

[Debug]
  show_material_props = true
[]
