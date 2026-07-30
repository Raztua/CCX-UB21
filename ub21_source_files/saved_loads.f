      module saved_loads
        implicit none
        real*8, allocatable, save :: ff_saved(:,:)
!       UB21 station data: ub21_stx(6 components, 11 stations, ne elements)
!       Stored independently of stx/mi(1) so INTEGRATIONPOINTS does not limit
!       the number of evaluation stations written to .frd.
        real*8, allocatable, save :: ub21_stx(:,:,:)
      end module saved_loads
