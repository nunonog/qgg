!==============================================================================================================
! functions and subroutines used for bedfiles 
!==============================================================================================================
!
!	https://www.cog-genomics.org/plink2/formats
!	00 Homozygous for first allele in .bim file
!	01 Missing genotype
!	10 Heterozygous
!	11 Homozygous for second allele in .bim file
!
!==============================================================================================================

  module kinds

  implicit none

  integer, parameter :: real64 = selected_real_kind(15, 307)
  integer, parameter :: int32 = selected_int_kind(9)


  end module kinds


  module f2cio
  
  use iso_c_binding

  implicit none
  private
  public :: fopen, fclose, fread, fwrite, fwrite_real, fread_real, fgets_char, cseek 

     
  interface

     function fopen(filename, mode) bind(C,name='fopen')
       !filename: file name to associate the file stream to 
       !mode: null-terminated character string determining file access mode 
       import
       implicit none
       type(c_ptr) fopen
       character(kind=c_char), intent(in) :: filename(*)
       character(kind=c_char), intent(in) :: mode(*)
     end function fopen

     function fclose(fp) bind(C,name='fclose')
       !fp: the file stream to close 
       import
       implicit none
       integer(c_int) fclose
       type(c_ptr), value :: fp
     end function fclose
     
     function fread(buffer,size,nbytes,fp) bind(C,name='fread')
       ! buffer: pointer to the array where the read objects are stored 
       ! size: size of each object in bytes 
       ! count: the number of the objects to be read 
       ! fp: the stream to read 
       import
       implicit none
       integer(c_int) fread
       integer(kind=c_int), value :: size
       integer(kind=c_int), value :: nbytes
       integer(kind=c_int8_t), dimension(nbytes) :: buffer 
       type(c_ptr), value :: fp
     end function fread
     
     function cseek(fp,offset,origin) bind(C,name='fseek')
       !fp: file stream to modify 
       !offset: number of characters to shift the position relative to origin 
       !origin: position to which offset is added (SEEK_SET, SEEK_CUR, SEEK_END) 
       import
       implicit none
       integer(c_int) cseek
       type(c_ptr), value :: fp
       integer(kind=c_int64_t), value :: offset
       integer(kind=c_int), value :: origin
     end function cseek
     
     function fwrite(buffer,size,nbytes,fp) bind(C,name='fwrite')
       ! buffer: pointer to the array where the write objects are stored 
       ! size: size of each object in bytes 
       ! count: the number of the objects to be written 
       ! fp: the stream to write 
       import
       implicit none
       integer(c_int) fwrite
       integer(kind=c_int), value :: size
       integer(kind=c_int), value :: nbytes
       integer(kind=c_int8_t), dimension(nbytes) :: buffer 
       type(c_ptr), value :: fp
     end function fwrite

     function fwrite_real(buffer,size,nbytes,fp) bind(C,name='fwrite')
       ! buffer: pointer to the array where the write objects are stored 
       ! size: size of each object in bytes 
       ! count: the number of the objects to be written 
       ! fp: the stream to write 
       import
       implicit none
       integer(c_int) fwrite_real
       integer(kind=c_int), value :: size
       integer(kind=c_int), value :: nbytes
       real(c_double), dimension(nbytes) :: buffer 
       type(c_ptr), value :: fp
     end function fwrite_real

     function fread_real(buffer,size,nbytes,fp) bind(C,name='fread')
       ! buffer: pointer to the array where the read objects are stored 
       ! size: size of each object in bytes 
       ! count: the number of the objects to be read 
       ! fp: the stream to read 
       import
       implicit none
       integer(c_int) fread_real
       integer(kind=c_int), value :: size
       integer(kind=c_int), value :: nbytes
       real(kind=c_double), dimension(nbytes) :: buffer 
       type(c_ptr), value :: fp
     end function fread_real

     function fgets_char(buffer,nbytes,fp) bind(C,name='fgets')
       ! buffer: pointer to the array where the read objects are stored 
       ! size: size of each object in bytes 
       ! count: the number of the objects to be read 
       ! fp: the stream to read 
       import
       implicit none
       integer(c_int) fgets_char
       integer(kind=c_int), value :: nbytes
       character(kind=c_char) :: buffer(1000) 
       type(c_ptr), value :: fp
     end function fgets_char



  end interface
     
  end module f2cio
     

  module bedfuncs

  use iso_c_binding
  use kinds 

  implicit none
    
  contains

  !============================================
  function raw2int(n,nbytes,raw) result(g)
  !============================================

  implicit none

  integer(c_int), intent(in) :: nbytes,n
  integer(c_int8_t), intent(in) :: raw(nbytes)
  integer(c_int) :: i,j,k,rawbits,g(n) 
  integer(c_int), dimension(4) :: rawcodes
 
  rawcodes = (/ 0, 3, 1, 2 /)
  ! 00 01 10 11

  g=0
  k=0
  do i=1,nbytes 
    do j=0,6,2
      k = k + 1
      rawbits = ibits(raw(i), j, 2)
      g(k) = rawcodes(rawbits+1)
      if (k==n) exit 
    enddo
    if (k==n) exit
  enddo

  end function raw2int


  !============================================
  function raw2real(n,nbytes,raw) result(w)
  !============================================

  implicit none
  integer(c_int), intent(in) :: nbytes,n
  integer(c_int8_t), intent(in) :: raw(nbytes)
  integer(c_int) :: i,j,k,rawbits
  real(real64) :: w(n)
  real(real64), dimension(4) :: rawcodes
 
  rawcodes = (/ 0.0D0, 3.0D0, 1.0D0, 2.0D0 /)
  ! 00 01 10 11
    
  w=0.0D0
  k=0
  do i=1,nbytes 
    do j=0,6,2
      k = k + 1
      rawbits = ibits(raw(i), j, 2)
      w(k) = rawcodes(rawbits+1)
      if (k==n) exit 
    enddo
    if (k==n) exit
  enddo

  end function raw2real


  !============================================
  function scalew(nr,g) result(w)
  !============================================

  implicit none

  integer(c_int), intent(in) :: nr
  real(real64), intent(in) :: g(nr)
  real(real64) :: mean,sd,tol,nsize,w(nr)

  tol=0.00001D0
  w=g
  nsize=dble(count(w<3.0D0))
  mean=sum(w, mask=w<3.0D0)/nsize
  where(w<3.0D0) 
    w=w-mean
  elsewhere
    w=0.0D0
  end where
  sd=sqrt(sum(w**2)/(nsize-1))
  if(sd>tol) w=w/sd
  if(sd<tol) w=0.0D0

  end function scalew

  end module bedfuncs


!==============================================================================================================
  subroutine readbed(n,nr,rws,nc,cls,impute,scale,direction,W,nbytes,fnRAW,nchars)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio
   
  implicit none
  
  integer(c_int) :: n,nr,nc,rws(nr),cls(nc),nbytes,impute,scale,direction(nc),nchars 
  real(real64) :: W(nr,nc),gsc(nr),gr(n),n0,n1,n2,nmiss,af,ntotal

  character(len=nchars, kind=c_char) :: fnRAW, filename
  character(len=20, kind=c_char) :: mode
  
  integer(kind=c_int8_t) :: raw(nbytes,nc), magic(3)
  integer(c_int) :: i,nchar,offset

  integer(kind=c_int64_t) :: pos14, nbytes14, offset14, i14
  integer(c_int):: cfres
  type(c_ptr):: fp
  
  offset=0
  nchar=index(fnRAW, '.bed')
  if(nchar>0) offset=3
  if(nchar==0) nchar=index(fnRAW, '.raw')

  nbytes14 = nbytes
  offset14 = offset

  filename = fnRAW(1:(nchar+3)) // C_NULL_CHAR
  mode =  'rb' // C_NULL_CHAR
  fp = fopen(filename, mode)

  if (c_double /= kind(1.0d0))  &
    error stop 'Default REAL isn''t interoperable with FLOAT!!'

  do i=1,nc
    i14=cls(i)
    pos14 = offset14 + (i14-1)*nbytes14 
    cfres=cseek(fp,pos14,0)            
    cfres=fread(raw(1:nbytes,i),1,nbytes,fp)
  enddo
  cfres=fclose(fp)
  
  ntotal=dble(nr)  

  W=0.0D0  
  do i=1,nc
    gr = raw2real(n,nbytes,raw(1:nbytes,i))
    if (impute==0) then
      if(direction(i)==0) gr=2.0D0-gr
      where(gr==3.0D0) gr=0.0D0
      where(gr==-1.0D0) gr=0.0D0
      W(1:nr,i) = gr(rws)
    endif
    if (impute==3) then
      if(direction(i)==0) gr=2.0D0-gr
      where(gr==-1.0D0) gr=3.0D0
      W(1:nr,i) = gr(rws)
    endif
    if (impute==1) then
      af=0.0D0
      gsc=gr(rws)
      nmiss=dble(count(gsc==3.0D0))
      n0=dble(count(gsc==0.0D0))
      n1=dble(count(gsc==1.0D0)) 
      n2=dble(count(gsc==2.0D0))
      if ( nmiss<ntotal ) af=(n1+2.0D0*n2)/(2.0D0*(ntotal-nmiss))
      W(1:nr,i) = gr(rws)
      where(W(1:nr,i)==3.0D0) W(1:nr,i)=2.0D0*af
      if(direction(i)==0) W(1:nr,i)=2.0D0-W(1:nr,i)
      if (scale==1) W(1:nr,i)=scalew(nr,W(1:nr,i))
      if ( nmiss==ntotal ) W(1:nr,i)=0.0D0
    endif
  enddo 

  end subroutine readbed
!==============================================================================================================
     
!==============================================================================================================
  subroutine bed2raw(m,cls,nbytes,append,fnBED,fnRAW,ncharbed,ncharraw)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio
  
  implicit none
  
  integer(c_int) :: m,cls(m),nbytes,append,ncharbed,ncharraw  
  character(len=ncharbed, kind=c_char) :: fnBED, filename1
  character(len=ncharraw, kind=c_char) :: fnRAW, filename2
  character(len=20, kind=c_char) :: mode1, mode2

  integer(kind=c_int8_t) :: raw(nbytes), magic(3)
  integer(c_int) :: i,offset,nchar

  integer(c_int64_t) :: pos14, nbytes14, offset14,i14

  integer(c_int):: cfres
  type(c_ptr):: fp1, fp2
  

  ! input file
  offset=3
  nchar=index(fnBED, '.bed')
  mode1 =  'rb' // C_NULL_CHAR
  filename1 = fnBED(1:(nchar+3)) // C_NULL_CHAR
  fp1 = fopen(filename1, mode1)
  cfres=fread(magic,1,3,fp1)

  ! output bedfile
  nchar=index(fnRAW, '.bed')
  if (nchar>0) then
   filename2 = fnRAW(1:(nchar+3)) // C_NULL_CHAR
   if (append==0) mode2 =  'wb' // C_NULL_CHAR
   if (append==0) fp2 = fopen(filename2, mode2)
   if (append==0) cfres=fwrite(magic,1,3,fp2) 
   if (append==1) mode2 =  'ab' // C_NULL_CHAR
   if (append==1) fp2 = fopen(filename2, mode2)
  endif

  ! output rawfile
  nchar=index(fnRAW, '.raw')
  if (nchar>0) then
   filename2 = fnRAW(1:(nchar+3)) // C_NULL_CHAR
   if (append==0) mode2 =  'wb' // C_NULL_CHAR
   if (append==0) fp2 = fopen(filename2, mode2)
   if (append==1) mode2 =  'ab' // C_NULL_CHAR
   if (append==1) fp2 = fopen(filename2, mode2)
  endif
  
  nbytes14 = nbytes
  offset14 = offset
  
  do i=1,m 
    if(cls(i)==1) then
    i14=i
    pos14 = offset14 + (i14-1)*nbytes14
    cfres=fread(raw,1,nbytes,fp1)
    cfres=fwrite(raw,1,nbytes,fp2)
    endif
  enddo 

  cfres=fclose(fp1)
  cfres=fclose(fp2)

  end subroutine bed2raw
!==============================================================================================================



!==============================================================================================================
  subroutine mpgrs(n,nr,rws,nc,cls,nbytes,fnRAW,nchars,nprs,s,prs,af,impute,direction,ncores)
!==============================================================================================================

  use kinds 
  use bedfuncs
  use iso_c_binding
  use f2cio

 
  
  implicit none
  
  integer(c_int) :: n,nr,nc,rws(nr),cls(nc),nbytes,nprs,ncores,thread,impute,direction(nc),nchars
  real(real64) :: gsc(nr),gr(n),n0,n1,n2,nmiss,af(nc),ntotal
  real(real64) :: prs(nr,nprs),s(nc,nprs),prsmp(nr,nprs,ncores)
  character(len=nchars, kind=c_char) :: fnRAW, filename
  character(len=20, kind=c_char) :: mode
  type(c_ptr):: fp
  integer(c_int) :: cfres 

  integer(kind=c_int8_t) :: raw(nbytes), magic(3)
  integer(c_int) :: i,j,nchar,offset

  integer(c_int64_t) :: pos14, nbytes14, offset14,i14


  integer(c_int), external :: omp_get_thread_num

  offset=0
  nchar=index(fnRAW, '.bed')
  if(nchar>0) offset=3
  if(nchar==0) nchar=index(fnRAW, '.raw')

  nbytes14 = nbytes
  offset14 = offset

  filename = fnRAW(1:(nchar+3)) // C_NULL_CHAR
  mode =  'rb' // C_NULL_CHAR
  fp = fopen(filename, mode)

  ntotal=dble(nr)  

  call omp_set_num_threads(ncores)

  prs=0.0d0
  prsmp=0.0d0

  !$omp parallel do private(i,j,gr,gsc,nmiss,n0,n1,n2,thread,i14,pos14,raw)
  do i=1,nc
    thread=omp_get_thread_num()+1
    i14=cls(i)
    pos14 = offset14 + (i14-1)*nbytes14
    cfres=cseek(fp,pos14,0)            
    cfres=fread(raw(1:nbytes),1,nbytes,fp)
    gr = raw2real(n,nbytes,raw)
    gsc=gr(rws)
    nmiss=dble(count(gsc==3.0D0))  
    if (impute==0) then
      where(gsc==3.0D0) gsc=0.0D0
    endif
    if (impute==1) then
      if(af(i)==0.0D0) then 
        n0=dble(count(gsc==0.0D0))
        n1=dble(count(gsc==1.0D0)) 
        n2=dble(count(gsc==2.0D0))
        if ( nmiss<ntotal ) af(i)=(n1+2.0D0*n2)/(2.0D0*(ntotal-nmiss))
      endif
      where(gsc==3.0D0) gsc=2.0D0*af(i)
    endif
    if(direction(i)==0) gsc=2.0D0-gsc
    if ( nmiss==ntotal ) gsc=0.0D0
    do j=1,nprs
       if (s(i,j)/=0.0d0) prsmp(1:nr,j,thread) = prsmp(1:nr,j,thread) + gsc*s(i,j)
    enddo  
  enddo 
  !$omp end parallel do

  cfres=fclose(fp)

  do i=1,nprs
    do j=1,ncores
      prs(1:nr,i) = prs(1:nr,i) + prsmp(1:nr,i,j)
    enddo
  enddo  
  
  end subroutine mpgrs
!==============================================================================================================

!==============================================================================================================
  subroutine gstat(n,nr,rws,nc,cls,nbytes,fnRAW,nchars,nt,s,yadj,setstat,af,impute,scale,direction,ncores)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio
 
  
  implicit none
  
  integer(c_int) :: n,nr,nc,rws(nr),cls(nc),nbytes,nt,ncores,thread,impute,scale,direction(nc),nchars
  real(real64) :: gsc(nr),gr(n),n0,n1,n2,nmiss,af(nc),ntotal
  real(real64) :: yadj(nr,nt),s(nc,nt),setstat(nc,nt)

  character(len=nchars, kind=c_char) :: fnRAW, filename
  character(len=20, kind=c_char) :: mode
  type(c_ptr):: fp
  integer(c_int) :: cfres 

  integer(kind=c_int8_t) :: raw(nbytes), magic(3)
  integer(c_int) :: i,j,stat,nchar,offset

  integer(c_int64_t) :: pos14, nbytes14, offset14,i14

  integer(c_int), external :: omp_get_thread_num


  offset=0
  nchar=index(fnRAW, '.bed')
  if(nchar>0) offset=3
  if(nchar==0) nchar=index(fnRAW, '.raw')

  nbytes14 = nbytes
  offset14 = offset

  filename = fnRAW(1:(nchar+3)) // C_NULL_CHAR
  mode =  'rb' // C_NULL_CHAR
  fp = fopen(filename, mode)


  ntotal=dble(nr)  

  call omp_set_num_threads(ncores)

  setstat=0.0d0
  !$omp parallel do private(i,j,i14,pos14,raw,gr,gsc,nmiss,n0,n1,n2,thread)
  do i=1,nc
    i14=cls(i)
    pos14 = offset14 + (i14-1)*nbytes14
    cfres=cseek(fp,pos14,0)            
    cfres=fread(raw(1:nbytes),1,nbytes,fp)
    gr = raw2real(n,nbytes,raw(1:nbytes))
    gsc=gr(rws)
    nmiss=dble(count(gsc==3.0D0))  
    if (impute==0) then
      where(gsc==3.0D0) gsc=0.0D0
    endif
    if (impute==1) then
      if(af(i)==0.0D0) then 
        n0=dble(count(gsc==0.0D0))
        n1=dble(count(gsc==1.0D0)) 
        n2=dble(count(gsc==2.0D0))
        if ( nmiss<ntotal ) af(i)=(n1+2.0D0*n2)/(2.0D0*(ntotal-nmiss))
      endif
      where(gsc==3.0D0) gsc=2.0D0*af(i)
    endif
    if(direction(i)==0) gsc=2.0D0-gsc
    if(scale==1) gsc=scalew(nr,gsc)
    if ( nmiss==ntotal ) gsc=0.0D0
    do j=1,nt
       if (s(i,j)/=0.0d0) setstat(i,j) = sum(yadj(1:nr,j)*gsc*s(i,j))
    enddo  
  enddo 
  !$omp end parallel do

  cfres=fclose(fp)

  end subroutine gstat
!==============================================================================================================


!==============================================================================================================
  subroutine summarybed(n,nr,rws,nc,cls,af,nmiss,n0,n1,n2,nbytes,fnRAW,nchars,ncores)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio
  
  implicit none
  
  integer(c_int) :: n,nr,nc,rws(nr),cls(nc),nbytes,g(n),grws(nr),ncores,nchars 
  real(real64) :: n0(nc),n1(nc),n2(nc),ntotal,af(nc),nmiss(nc)
  character(len=nchars, kind=c_char) :: fnRAW, filename
  character(len=20, kind=c_char) :: mode
  type(c_ptr):: fp
  integer(c_int) :: cfres 

  integer(kind=c_int8_t) :: raw(nbytes), magic(3)
  integer(c_int) :: i,nchar,offset

  integer(c_int64_t) :: pos14, nbytes14, offset14,i14

  integer(c_int), external :: omp_get_thread_num

  call omp_set_num_threads(ncores)

  offset=0
  nchar=index(fnRAW, '.bed')
  if(nchar>0) offset=3
  if(nchar==0) nchar=index(fnRAW, '.raw')

  nbytes14 = nbytes
  offset14 = offset

  af=0.0D0
  nmiss=0.0D0
  ntotal=dble(nr) 

  filename = fnRAW(1:(nchar+3)) // C_NULL_CHAR
  mode =  'rb' // C_NULL_CHAR

  ! process serial
  if (ncores==1) then
    fp = fopen(filename, mode)
    do i=1,nc 
      i14=cls(i)
      pos14 = offset14 + (i14-1)*nbytes14
      cfres=cseek(fp,pos14,0)            
      cfres=fread(raw(1:nbytes),1,nbytes,fp)
      g = raw2int(n,nbytes,raw)
      grws = g(rws)
      nmiss(i)=dble(count(grws==3))
      n0(i)=dble(count(grws==0))
      n1(i)=dble(count(grws==1)) 
      n2(i)=dble(count(grws==2))
      if ( nmiss(i)<ntotal ) af(i)=(n1(i)+2.0D0*n2(i))/(2.0D0*(ntotal-nmiss(i)))
    enddo 
    cfres=fclose(fp)
  endif

  ! process parallel
  if (ncores>1) then
    fp = fopen(filename, mode)
    !$omp parallel do private(i,i14,pos14,raw,g,grws)
    do i=1,nc 
      i14=cls(i)
      pos14 = offset14 + (i14-1)*nbytes14
      cfres=cseek(fp,pos14,0)            
      cfres=fread(raw(1:nbytes),1,nbytes,fp)
      g = raw2int(n,nbytes,raw)
      grws = g(rws)
      nmiss(i)=dble(count(grws==3))
      n0(i)=dble(count(grws==0))
      n1(i)=dble(count(grws==1)) 
      n2(i)=dble(count(grws==2))
      if ( nmiss(i)<ntotal ) af(i)=(n1(i)+2.0D0*n2(i))/(2.0D0*(ntotal-nmiss(i)))
    enddo 
    !$omp end parallel do
    cfres=fclose(fp)
  endif



  end subroutine summarybed
!==============================================================================================================

!==============================================================================================================
  subroutine grmbed(n,nr,rws,nc,cls1,cls2,scale,nbytes,fnRAW,nchars,msize,ncores,fnG,gmodel)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio
  
  implicit none
  
  integer(c_int) :: i,j,n,nr,nc,rws(nr),cls1(nc),cls2(nc),impute,scale,nbytes,ncores,msize,nchar,ncw,gmodel,direction(nc),nchars
  real(real64) :: G(nr,nr), W1(nr,msize),W2(nr,msize), w(nr), traceG
  character(len=nchars, kind=c_char) :: fnRAW
  character(len=1000, kind=c_char) :: fnG, filename
  character(len=20, kind=c_char) :: mode
  type(c_ptr):: fp
  integer(c_int) :: cfres 

  call omp_set_num_threads(ncores)

  G = 0.0D0
  W1 = 0.0D0
  W2 = 0.0D0
  w=0.0d0

  impute=1
  direction=1 

  do i=1,nc,msize

    if((i+msize-1)<nc) ncw = size(cls1(i:(i+msize-1)))
    if((i+msize-1)>=nc) ncw = size(cls1(i:nc))          
  
    select case (gmodel)

      case (1) ! additive 
      call readbed(n,nr,rws,ncw,cls1(i:(i+ncw-1)),impute,scale,direction,W1(:,1:ncw),nbytes,fnRAW,nchars)
      call dsyrk('u', 'n', nr, ncw, 1.0D0, W1(:,1:ncw), nr, 1.0D0, G, nr)

      case (2) ! dominance
      scale=2
      call readbed(n,nr,rws,ncw,cls1(i:(i+ncw-1)),impute,scale,direction,W1(:,1:ncw),nbytes,fnRAW,nchars)
      call dsyrk('u', 'n', nr, ncw, 1.0D0, W1(:,1:ncw), nr, 1.0D0, G, nr)

      case (3) ! epistasis
      call readbed(n,nr,rws,ncw,cls1(i:(i+ncw-1)),impute,scale,direction,W1(:,1:ncw),nbytes,fnRAW,nchars)
      call readbed(n,nr,rws,ncw,cls2(i:(i+ncw-1)),impute,scale,direction,W2(:,1:ncw),nbytes,fnRAW,nchars)
      do j=1,ncw
        W1(:,j) = W1(:,j)*W2(:,j)
      enddo
      call dsyrk('u', 'n', nr, ncw, 1.0D0, W1(:,1:ncw), nr, 1.0D0, G, nr)

      case (4) ! epistasis hadamard 
      call readbed(n,nr,rws,ncw,cls1(i:(i+ncw-1)),impute,scale,direction,W1(:,1:ncw),nbytes,fnRAW,nchars)
      call dsyrk('u', 'n', nr, ncw, 1.0D0, W1(:,1:ncw), nr, 1.0D0, G, nr)

    end select
  
  enddo
 
  traceG = 0.0D0
  do i=1,size(G,1)
      traceG = traceG + G(i,i)
  enddo
  traceG = traceG/dble(nr) 
 
  do i=1,size(G,1)
    do j=i,size(G,1)
      G(i,j) = G(i,j)/traceG
      G(j,i) = G(i,j)
    enddo
  enddo

  nchar=index(fnG, '.grm')
  mode =  'wb' // C_NULL_CHAR
  filename = fnG(1:(nchar+3)) // C_NULL_CHAR
  fp = fopen(filename, mode)
  do j=1,size(G,1)
    if (gmodel<4) w = G(1:size(G,1),j)
    if (gmodel==4) w = G(1:size(G,1),j)**2
    cfres=fwrite_real(w,8,nr,fp)
  enddo
  cfres=fclose(fp)

  end subroutine grmbed
!==============================================================================================================


!==============================================================================================================
  subroutine solvebed(n,nr,rws,nc,cls,scale,nbytes,fnRAW,nchars,ncores,nit,lambda,tol,y,g,e,s,mean,sd)
!==============================================================================================================

  use kinds 
  use bedfuncs 
  use iso_c_binding
  use f2cio

  !implicit none
  
  integer(c_int) :: i,n,nr,nc,rws(nr),cls(nc),scale,nbytes,nit,it,ncores,nchar,offset,nchars
  real(real64) :: y(n),e(n),raww(n),w(n),g(n)
  real(real64) :: dww(nc),s(nc),os(nc),lambda(nc),mean(nc),sd(nc)
  real(real64) :: lhs,rhs,snew,tol
  character(len=nchars, kind=c_char) :: fnRAW, filename
  character(len=20, kind=c_char) :: mode
  type(c_ptr):: fp
  integer(c_int) :: cfres 
  real(real64), external  :: ddot

  integer(kind=c_int8_t) :: raw(nbytes), magic(3)
 
  integer(c_int64_t) :: pos14,nbytes14,offset14,i14


  call omp_set_num_threads(ncores)

  if (scale==0) scale = 1

  offset=0
  nchar=index(fnRAW, '.bed')
  if(nchar>0) offset=3
  if(nchar==0) nchar=index(fnRAW, '.raw')

  nbytes14 = nbytes
  offset14 = offset

  filename = fnRAW(1:(nchar+3)) // C_NULL_CHAR
  mode =  'rb' // C_NULL_CHAR
  fp = fopen(filename, mode)

  ! genotypes coded 0,1,2,3=missing => where 0,1,2 means 0,1,2 copies of alternative allele 
  do i=1,nc
    i14=cls(i)
    pos14 = offset14 + (i14-1)*nbytes14
    cfres=cseek(fp,pos14,0)            
    cfres=fread(raw(1:nbytes),1,nbytes,fp)
    raww = raw2real(n,nbytes,raw)
    where (raww<3.0D0)
      w = (raww-mean(i))/sd(i)
    elsewhere
      w = 0.0D0
    end where
    dww(i)=dot_product(w(rws),w(rws))
    if(s(i).eq.0.0D0) then
      s(i)=(ddot(nr,w(rws),1,y(rws),1)/dww(i))/nc
    endif     
  enddo

  os=s
  e=0.0D0
  e(rws)=y(rws)
  do it=1,nit
    g=0.0D0
    open(unit=13,file=fnRAW(1:(nchar+3)), status='old', form='unformatted', access='direct', recl=nbytes)
    do i=1,nc
    i14=cls(i)
    pos14 = offset14 + (i14-1)*nbytes14
    cfres=cseek(fp,pos14,0)            
    cfres=fread(raw(1:nbytes),1,nbytes,fp)
      raww = raw2real(n,nbytes,raw)
        where (raww<3.0D0)
        w = (raww-mean(i))/sd(i)
      elsewhere
        w = 0.0D0
      end where
      lhs=dww(i)+lambda(i)
      rhs=dot_product(w(rws),e(rws)) 
      rhs=rhs + dww(i)*s(i)
      snew=rhs/lhs
      e(rws)=e(rws) - w(rws)*(snew-s(i))
      s(i)=snew
      g=g+w*s(i)
    enddo
    if( (sum((s-os)**2)/sqrt(dble(nc)))<tol) exit  
    os=s  
  enddo

  cfres=fclose(fp)
  
  nit=it
  tol=sum((s-os)**2)
  
  end subroutine solvebed
!==============================================================================================================



!==============================================================================================================
  subroutine psets(m,stat,nsets,setstat,msets,p,np,ncores)
!==============================================================================================================

  use kinds 
  use iso_c_binding
  implicit none
  
  integer(c_int) :: m,nsets,msets(nsets),p(nsets),np,ncores   
  integer(c_int) :: i,j,k1,k2,maxm,thread,multicore   
  real(real64) :: stat(m),setstat(nsets),u,pstat
  integer(c_int), external :: omp_get_thread_num

  p=0

  multicore=0
  if (ncores>1) multicore=1
 
  maxm = m - maxval(msets) - 1

  select case (multicore)

  case (0) ! no multicore 

  do i=1,nsets
    do j=1,np
      call random_number(u)
      k1 = 1 + floor(maxm*u)  ! sample: k = n + floor((m+1-n)*u) n, n+1, ..., m-1, m
      k2 = k1+msets(i)-1
      pstat = sum(stat(k1:k2))
      if (pstat > setstat(i)) p(i) = p(i) + 1
    enddo
  enddo   

  case (1) ! multicore 

  call omp_set_num_threads(ncores)

  !$omp parallel do private(i,j,k1,k2,u,pstat)
  do i=1,nsets
    thread=omp_get_thread_num()+1 
    do j=1,np
      call random_number(u)
      k1 = 1 + floor(maxm*u)  ! sample: k = n + floor((m+1-n)*u) n, n+1, ..., m-1, m
      k2 = k1+msets(i)-1
      pstat = sum(stat(k1:k2))
      if (pstat > setstat(i)) p(i) = p(i) + 1
    enddo
  enddo   
  !$omp end parallel do

  end select

  end subroutine psets
!==============================================================================================================



!==============================================================================================================
  subroutine eiggrm(n,GRM,evals,ncores)
!==============================================================================================================
! calls the LAPACK diagonalization subroutine dsyev       
!  input:  G(n,n) = real symmetric matrix to be diagonalized
!            n  = size of G                               
!  output: G(n,n) = orthonormal eigenvectors of G           
!        eig(n) = eigenvalues of G in ascending order     
!==============================================================================================================
  use kinds 
  use iso_c_binding

  implicit none

  external dsyev
  integer(c_int) :: n,l,info,ncores
  real(real64) :: GRM(n,n),evals(n),work(n*(3+n/2))

  call omp_set_num_threads(ncores)

  info=0
  l=0

  l=n*(3+n/2)
  call dsyev('V','U',n,GRM,n,evals,work,l,info)

  end subroutine eiggrm
!==============================================================================================================




