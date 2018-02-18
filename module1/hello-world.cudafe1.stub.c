#define __NV_CUBIN_HANDLE_STORAGE__ static
#include "crt/host_runtime.h"
#include "hello-world.fatbin.c"
extern void __device_stub__Z5helloPcPi(char *, int *);
static void __nv_cudaEntityRegisterCallback(void **);
static void __sti____cudaRegisterAll(void);
#pragma section(".CRT$XCU",read)
__declspec(allocate(".CRT$XCU"))static void (*__dummy_static_init__sti____cudaRegisterAll[])(void) = {__sti____cudaRegisterAll};
void __device_stub__Z5helloPcPi(char *__par0, int *__par1){__cudaSetupArgSimple(__par0, 0Ui64);__cudaSetupArgSimple(__par1, 8Ui64);__cudaLaunch(((char *)((void ( *)(char *, int *))hello)));}
#line 13 "hello-world.cu"
void hello( char *__cuda_0,int *__cuda_1)
#line 14 "hello-world.cu"
{__device_stub__Z5helloPcPi( __cuda_0,__cuda_1);

}
#line 1 "hello-world.cudafe1.stub.c"
static void __nv_cudaEntityRegisterCallback( void **__T0) {  __nv_dummy_param_ref(__T0); __nv_save_fatbinhandle_for_managed_rt(__T0); __cudaRegisterEntry(__T0, ((void ( *)(char *, int *))hello), _Z5helloPcPi, (-1)); }
static void __sti____cudaRegisterAll(void) {  __cudaRegisterBinary(__nv_cudaEntityRegisterCallback);  }
