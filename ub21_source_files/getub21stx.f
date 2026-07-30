!
!     C-callable interface to retrieve UB21 station stress/force data
!     from the ub21_stx module variable.
!
!     Called from C as:
!       getub21stx_(&nelem_1based, out_array_66)
!
!     out_array_66 must be at least 6*11=66 doubles.
!     Layout: out_array_66[6*j + k] = ub21_stx(k+1, j+1, nelem)
!     for j=0..10 (station), k=0..5 (component).
!
      subroutine getub21stx(nelem, out_array)
!
      use ub21_module
      implicit none
!
      integer nelem
      real*8  out_array(6,11)
!
      integer j, k
!
      if (allocated(ub21_stx)) then
         do j = 1, 11
            do k = 1, 6
               out_array(k,j) = ub21_stx(k, j, nelem)
            enddo
         enddo
      else
         do j = 1, 11
            do k = 1, 6
               out_array(k,j) = 0.d0
            enddo
         enddo
      endif
!
      return
      end
