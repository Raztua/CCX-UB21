!     Module holding shared data for UB21 custom beam element.
!
!     ff_saved(60, ne):   saved element force vectors from assembly phase,
!                         used in resultsmech_ub21 to recover reactions.
!
!     ub21_stx(6, 11, ne): 11-station stress/force data per UB21 element.
!                          Indexed as ub21_stx(component, station, element).
!                          Stations 1..11 correspond to xi = 0.0, 0.1 .. 1.0.
!                          Populated in resultsmech_ub21, read by getub21stx
!                          for .frd visualisation (independent of mi(1) /
!                          INTEGRATIONPOINTS so all 11 stations are always
!                          available regardless of *USER ELEMENT settings).
!
      module ub21_module
        implicit none
        real*8, allocatable, save :: ff_saved(:,:)
        real*8, allocatable, save :: ub21_stx(:,:,:)
      end module ub21_module
