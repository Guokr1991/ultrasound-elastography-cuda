#include  "cuda_main.cuh"


#ifdef  _CUDA_MAIN_CUH
#include  "SysConfig.h"
#include  "CElasto.h"
#include  "FileUtility.h"
#include <fstream>
#include <string>
#include <iostream>
#include <time.h>
#include <device_launch_parameters.h>
#include <device_functions.h>
#include <math_functions.h>
#include  <math.h>
#include <string.h>
#include <cstdio>
#include "opencv/highgui.h"
#include "opencv/cv.h"
#include "ImageFunc.h"


#endif


//�ں˺�����device����


//��Ҫ���ģ��ÿ�GPUоƬֻ��֧��1024��threads per  block !!!      changed  by  wong   2016/06/08

//�����������˲���    ���˲�           changed  by  wong    2016/5/13

__global__ void Bandpass_front_1(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)
{
	//float muData[40];

	//k  = blockIdx.x   i = blockIdx.y;
	float data_sum;

	float data_1;

	data_sum = 0.0;

	//	__shared__     float     data_sum[8192];



	/*for (int i = 0; i < iParaLen; i++)
	{
	muData[i] = *(param + i);
	}*/

	if (threadIdx.x <= iParaLen - 1)                                         //������ĿС�ڵ��ڳ�ͷ��Ŀ
	{

		for (int i = 0; i <= threadIdx.x; i++)
		{


			data_1 = *(tInput + blockIdx.x*iWidth + threadIdx.x - i);      //b(0)*x(n-0)+b(1)*x(n-1)+...+b(n)*x(0)   

			data_sum += (data_1*param[i]);

		}

		data_1 = *(tInput + blockIdx.x * iWidth);                          // x(0)


		for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
		{
			data_sum += (data_1*param[j]);                                 //b(n+1)*x(0)+...+b(nb-2)*x(0)
		}

		*(tOutPut + blockIdx.x * iWidth + threadIdx.x) = data_sum;



	}
	else                                                                  //������Ŀ���ڳ�ͷ��Ŀ            
	{
		//data_1 = (tInput + blockIdx.x*iWidth + blockIdx.y - threadIdx.x)->x;
		for (int i = 0; i <= iParaLen - 1; i++)
		{

			data_1 = *(tInput + blockIdx.x*iWidth + threadIdx.x - i);   //b(0)*x(n-0)+b(1)*x(n-1)+...+b(nb-2)*x(n-(nb-2))  

			data_sum += (data_1*param[i]);

		}

		*(tOutPut + blockIdx.x * iWidth + threadIdx.x)= data_sum;

	}

}




//worker for  zero-phase filter  ,1024  threads  limited   .   changed   by  wong   2016/06/12

//test  result  : ok        wong    2016/06/13  

__global__ void Bandpass_front_1024(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)     {

	 float data_sum;

	 float data_1;

	 data_sum = 0.0;

	 int   line_serial;

	 int    bid = blockIdx.x;


	   line_serial = bid / 8;



	 int  line_mod = bid % 8;


//	 line_serial  = bid / 16;                            //changed   by wong 


//	 int  line_mod = bid % 16;                         //changed  by  wong 




	 if ((0 == line_mod))    {                                                                     //������                  

		 if ((threadIdx.x <= iParaLen - 1))                                                       //������ĿС�ڵ��ڳ�ͷ��Ŀ,�����ǳ�����
		 {

			 for (int i = 0; i <= threadIdx.x; i++)
			 {


				 data_1 = *(tInput + line_serial * iWidth + threadIdx.x - i);                  //b(0)*x(n-0)+b(1)*x(n-1)+...+b(n)*x(0)   

				 data_sum += (data_1*param[i]);

			 }


			 data_1 = *(tInput + line_serial * iWidth);                                      // x(0)


			 for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
			 {
				 data_sum += (data_1*param[j]);                                                    //b(n+1)*x(0)+...+b(nb-2)*x(0)
			 }

			 *(tOutPut + line_serial * iWidth + threadIdx.x) = data_sum;



		 }

		 else  if ((threadIdx.x > iParaLen - 1))   {                                               //������Ŀ���ڵ��ڳ�ͷ��Ŀ,�����ǳ�����

			 //data_1 = (tInput + blockIdx.x*iWidth + blockIdx.y - threadIdx.x)->x;
			 for (int i = 0; i <= iParaLen - 1; i++)
			 {

				 data_1 = *(tInput + line_serial *iWidth + threadIdx.x - i);                 //b(0)*x(n-0)+b(1)*x(n-1)+...+b(nb-2)*x(n-(nb-2))  

				 data_sum += (data_1*param[i]);

			 }

			 *(tOutPut + line_serial * iWidth + threadIdx.x) = data_sum;


		 }


	 }

	else                                                                                 //�ǳ����� (Ĭ��������Ŀ���ڵ��ڳ�ͷ��Ŀ)        
	{

		for (int i = 0; i <= iParaLen - 1; i++)
		{

			data_1    = *(tInput + blockIdx.x*blockDim.x+ threadIdx.x - i);   //b(0)*x(n-0)+b(1)*x(n-1)+...+b(nb-2)*x(n-(nb-2))  

			data_sum += (data_1*param[i]);

		}

		*(tOutPut + blockIdx.x*blockDim.x + threadIdx.x) = data_sum;

	}

//	 __syncthreads();
 


}




//��Ҫ���ģ��ÿ�GPUоƬֻ��֧��1024��threads per  block !!!      changed  by  wong   2016/06/08

//�����������˲���   ���˲�                          changed  by  wong     2016/5/13
__global__ void Bandpass_back_1(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)
{
	/*
	if (threadIdx.x < iParaLen - 1)                                     //  n  >= nb-1
	{
	return;                                                            //  �˴�������     changed  by  wong
	}
	//   changed   by  wong     2016/5/11
	*/                                                                 // �˴�û�п���С��nb-1���������Ҫ�������


	float data_1;

	float data_sum;

	data_sum = 0.0;



	if (threadIdx.x <= iParaLen - 1)   {                                //  ���ݳ���С�ڵ����˲�����ͷ����


		for (int i = 0; i <= threadIdx.x; i++)
		{


			data_1 = *(tInput + blockIdx.x*iWidth + iWidth - 1 - threadIdx.x + i);      //

			data_sum += (data_1*param[i]);

		}


		data_1 = *(tInput + blockIdx.x * iWidth + iWidth - 1);                        //  x(N-1) 


		for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
		{

			data_sum += (data_1*param[j]);                                            // b(n+1)*x(N-1)+...+b(nb-1)*x(N-1) 

		}


		*(tOutPut + blockIdx.x * iWidth + iWidth - 1 - threadIdx.x) = data_sum;                 // y(n)

	}

	else    {                                                                       //���ݳ��ȴ����˲�����ͷ����         


		for (int i = 0; i <= iParaLen - 1; i++)
		{
			data_1 = *(tInput + blockIdx.x*iWidth + iWidth - 1 - threadIdx.x + i);

			data_sum += (data_1*param[i]);                                         //  y(N-1-n) = b(0)*x(N-1-n+0) +b(1)*x(N-1-n+1)+...+b(nb-1)*x(N-1-n+nb-1)

		}

		*(tOutPut + blockIdx.x * iWidth + iWidth - 1 - threadIdx.x)   = data_sum;




	}



	__syncthreads();  

}




//  worker for  zero-phase filter  ,1024  threads  limited   .   changed   by  wong   2016/06/12

//  test  result  : ok        wong    2016/06/13   

__global__ void Bandpass_back_1024(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)   {


	float  data_1;

	float  data_sum;

	data_sum = 0.0;


	int   line_serial;

	int    bid = blockIdx.x;


	line_serial = bid / 8;



	int  line_mod = bid % 8;


//	line_serial = bid / 16;


//	int  line_mod = bid % 16;







	if ((0 == line_mod))    {                                                                     // ������   


		if (threadIdx.x <= iParaLen - 1)   {                                                      // ���ݳ���С�ڵ����˲�����ͷ����,�����ǳ�����


			for (int i = 0; i <= threadIdx.x; i++)
			{

				 
				data_1 = *(tInput + line_serial*iWidth + iWidth - 1 - threadIdx.x + i);      // ��������

				data_sum += (data_1*param[i]);

			}


			data_1 = *(tInput + line_serial * iWidth + iWidth - 1);                          // x(N-1) 


			for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
			{

				data_sum += (data_1*param[j]);                                                   // b(n+1)*x(N-1)+...+b(nb-1)*x(N-1) 

			}


			*(tOutPut + line_serial * iWidth + iWidth-1 - threadIdx.x) = data_sum;              // y(n)      

		}

		else  if (threadIdx.x  >iParaLen - 1)   {                                              // ���ݳ��ȴ����˲�����ͷ����,�����ǳ�����         

			data_sum = 0;

			for (int i = 0; i <= iParaLen - 1; i++)
			{
				data_1 = *(tInput + line_serial*iWidth + iWidth - 1 - threadIdx.x + i);

				data_sum += (data_1*param[i]);                                               //  y(N-1-n) = b(0)*x(N-1-n+0) +b(1)*x(N-1-n+1)+...+b(nb-1)*x(N-1-n+nb-1)

			}

			*(tOutPut + line_serial * iWidth + iWidth - 1 - threadIdx.x) = data_sum;




		}



	}  

	else  {                                                                                 //  �ǳ����� (Ĭ��������Ŀ���ڵ��ڳ�ͷ��Ŀ)    

		    data_sum = 0;
		  

		for (int i = 0; i <= iParaLen - 1; i++)
		{
			data_1 = *(tInput + line_serial*iWidth + iWidth - 1 - (threadIdx.x + line_mod*blockDim.x) + i);

			data_sum += (data_1*param[i]);                                               //  y(N-1-n) = b(0)*x(N-1-n+0) +b(1)*x(N-1-n+1)+...+b(nb-1)*x(N-1-n+nb-1)

		}

		*(tOutPut + line_serial * iWidth + iWidth - 1 - (threadIdx.x + line_mod*blockDim.x)) = data_sum;




	}
	
	
	
	
	}





















//changed   by  wong      2016/5/13

__device__      void   xcorr_cuda(const  Complex* templateMat_startID, const Complex* objectMat_startID, Complex*resultMat_startID)     {


	for (int i = 0; i < 101; i++)   {


		Complex     sum_object = 0;

		Complex     frac_object = 0;


		Complex     pow_template = 0;


		Complex      pow_object = 0;


		Complex     result = 0;


		//sum_object 

		for (int j = 0; j < 100; j++)  {


			sum_object += *(objectMat_startID + i + j);


		}

		//  ave

		Complex   ave_object =   sum_object / 100;


		//fraction

		for (int j = 0; j < 100; j++)  {

			Complex    tmp = *(templateMat_startID + j) *  (*(objectMat_startID + i + j) - ave_object);


			frac_object += tmp;

		}


		//pow   temp

		for (int j = 0; j < 100; j++)  {


			pow_template += *(templateMat_startID + j) * *(templateMat_startID + j);

		}

		//pow   objectMat 

		for (int j = 0; j < 100; j++)  {


			pow_object += *(objectMat_startID + i + j)* * (objectMat_startID + i + j);

		}

		//result

		result = sqrt(pow_template*pow_object);

		//output

		*(resultMat_startID + i) = frac_object / result;

	}


}


//changed   by  wong    2016/5/13

__device__      void   minMax_cuda(Complex*resultMat_startID, Complex* min_value, Complex*  max_value, int * max_location)   {

//	int      max_loc_temp = 0;

//	int      min_loc_temp = 0;

//	float      max_temp   = 0;

//	float      min_temp   = 0;

	//�����ֵ��λ��

	for (int i = 0; i < 101; i++)  {

		if (*(resultMat_startID + i) >= *max_value)  {

			*max_location   = i;

			*max_value = *(resultMat_startID + i);



		}

	}

	//����Сֵ��λ��

//	for (int i = 0; i < 101; i++)  {

//		if (*(resultMat_startID + i) <= *min_value)  {

		//	min_loc_temp = i;

//			*min_value = *(resultMat_startID + i);

			
//		}


//	}

	//���

//	*min_value = min_temp;

//	*max_value = max_temp;

//	max_location = max_loc_temp;

}


 
//changed  by   wong      2016/5/17

__device__    void    interp_cuda(Complex*resultMat_startID, int *  max_loc, Complex*max_value, int * multiWin, int * winSize, Complex*  displace)     {

	Complex*pre = (Complex*)resultMat_startID + *max_loc - 1;

	Complex*next = (Complex*)resultMat_startID + *max_loc + 1;


	*displace   = (*multiWin - 1) * *winSize / 2 - *max_loc - (*pre - *next) / (2 * (*pre - 2 * *max_value + *next));


}





// ���Ϊλ��299*799����

// test   result :  ok     wong   2016/06/24

__global__   void  displacement_api_cuda(Complex*disInputCuda, int rows, int cols, int  multiWin, int winSize, int  stepSize, templateMat*templateMatShare, objectMat* objectMatShare, resultMat*resultMatShare, Complex*min, Complex*max, int*max_location, Complex* displacement )      {


	int   out_offset = blockIdx.x *blockDim.x + threadIdx.x;                     // ���λ�ƾ���ƫ��ֵ

	int    bid       = blockIdx.x ;                                              //  ��Ӧblock ID 
	
	int    tid       = threadIdx.x;                                             //   ��Ӧthread ID 


   //����ʹ��3D���飬��Ϊ�����ڴ治���ã�ֻ��49152���ֽ�each block 

	//�����ڴ�

	//����ȫ���ڴ棡����

//	__shared__     Complex*     templateMatShare[THREAD_NUM];        //100�׵�ַ

//	__shared__     Complex*     objectMatShare[THREAD_NUM];          //200�׵�ַ

//	__shared__     Complex*     resultMatShare[THREAD_NUM];          //101�׵�ַ 


//	__shared__     templateMat   templateMatShare[THREAD_NUM];

//	__shared__     objectMat     objectMatShare[THREAD_NUM];

//	__shared__     resultMat     resultMatShare[THREAD_NUM];


//	  Complex*templateMatShare;                          //   ģ���ڴ���GPU����         ���Ǿֲ�����                  


//	  Complex*objectMatShare;                           //    Ŀ���ڴ���GPU����         ���Ǿֲ�����


//	  Complex*resultMatShare;                           //    ƥ������GPU����         ���Ǿֲ�����




//	cudaMalloc(&templateMatShare, winSize* sizeof(Complex));             //ģ�����


//	cudaMalloc(&objectMatShare, winSize*multiWin* sizeof(Complex));     //Ŀ�����


//	cudaMalloc(&resultMatShare, (winSize + 1)* sizeof(Complex));        //�������




//	 templateMatShare[out_offset].elem   = (Complex*)(disInputCuda + blockIdx.x*cols + (multiWin - 1) * winSize / 2 + threadIdx.x * stepSize);
		







	    Complex*templateMatID;                               //ID


	  Complex*objectMatID;                                //ID



	//12784�ֽ�

//	__shared__     Complex*     min[THREAD_NUM];

//	__shared__     Complex*     max[THREAD_NUM];

//	__shared__      int        max_location[THREAD_NUM];

//	__shared__    Complex*     displacement[THREAD_NUM];




	//׼���������      �߳̿������� �����ù����ڴ�


	//	(templateMat*)(templateMat_startID + threadIdx.x)->elem = (Complex*)(disInputCuda + blockIdx.x*cols + (multiWin - 1) * winSize / 2 + threadIdx.x * stepSize);

	      templateMatID = (Complex*)(disInputCuda + blockIdx.x*cols + (multiWin - 1) * winSize / 2 + threadIdx.x * stepSize);




		  for (int i = 0; i < 100;i++)  {

			  if (i < 64)    {
			  
				  templateMatShare[out_offset].tempData.elem[i]= *(templateMatID + i);
			  
			  }
		  
			  else
				      

			    templateMatShare[out_offset].tempData.atom[i-64] = *(templateMatID + i);
		  
		  
		  }



		  /*      change   by wong 

		  for (int i = 0; i < 64; i++) {

		   templateMatShare[out_offset].elem[i] = *(templateMatID+i);


	//		 *(templateMatShare[out_offset].elem+i)  = *(templateMatID + i);

		  }


		  for (int j = 0; j < 36; j++) {

			  templateMatShare[out_offset].atom[j] = *(templateMatID + j+64);


			  //		 *(templateMatShare[out_offset].elem+i)  = *(templateMatID + i);

		  }      change  by  wong 

    */       




		  objectMatID   = (Complex*)(disInputCuda + (blockIdx.x + 1)*cols + threadIdx.x * stepSize);


   
		  for (int i = 0; i < 200; i++)  {

			  if (i<64)
				  objectMatShare[out_offset].objData.elem_0[i]     = *(objectMatID + i);
			  else if (i<128)
				  objectMatShare[out_offset].objData.elem_1[i - 64] = *(objectMatID + i);

			  else if (i<192)
				  objectMatShare[out_offset].objData.elem_2[i - 128] = *(objectMatID + i);
			  else
				  objectMatShare[out_offset].objData.atom[i - 192]   = *(objectMatID + i);

			  //	  *(objectMatShare[out_offset].elem + i) = *(objectMatID + i);

		  }

       



		  for (int i = 0; i < 101; i++)  {
		   
			  if (i<64)
				  resultMatShare[out_offset].resData.elem[i]   = 0;
		   
			  else
				  resultMatShare[out_offset].resData.atom[i-64] = 0;
		  
		  }
		 





		  /*    change  by wong  
             
		  for (int i = 0; i < 192; i++)  {
		  
			  if (i<64) 
			  objectMatShare[out_offset].elem_0[i]       = *(objectMatID+i);
			  else if (i<128)
			  objectMatShare[out_offset].elem_1[i-64]    = *(objectMatID + i);

			  else 
			  objectMatShare[out_offset].elem_2[i - 128] = *(objectMatID + i);

		//	  *(objectMatShare[out_offset].elem + i) = *(objectMatID + i);
		  
		  }
  


		  for (int j = 0; j < 8; j++) {

			  objectMatShare[out_offset].atom[j] = *(templateMatID + j + 192);


			  //		 *(templateMatShare[out_offset].elem+i)  = *(templateMatID + i);

		  }      change  by  wong 
		   

   */
   




//	__syncthreads();

//	cudaThreadSynchronize();

//	cudaDeviceSynchronize();



	//�������

		  xcorr_cuda(templateMatShare[out_offset].tempData.elem, objectMatShare[out_offset].objData.elem_0, resultMatShare[out_offset].resData.elem);


	//	__syncthreads();

//	cudaThreadSynchronize();


	//�������ֵ

		minMax_cuda(resultMatShare[out_offset].resData.elem, &min[out_offset], &max[out_offset], &max_location[out_offset]);


//	__syncthreads();

//	cudaThreadSynchronize();

	//��ֵ

		interp_cuda(resultMatShare[out_offset].resData.elem, &max_location[out_offset], &max[out_offset], &multiWin, &winSize, &displacement[out_offset]);


//		__syncthreads();

//	cudaThreadSynchronize();


	//ȥ����


	//λ�Ƶ���


	//��ֵ�˲�


	//�����ֵ

	//  *��disOutputCuda+bid��     =    displacement   ��

//	disOutputCuda[out_offset] = *displacement[threadIdx.x];


}



//ȥ����        changed  by wong    2016/5/18

__global__  void   remove_singular_cuda(Complex*disOutputCuda, Complex*singularOutputCuda)   {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                                           // ���λ�ƾ���ƫ��ֵ

	int    bid   = blockIdx.x;                                                                     //  block   id

	int    tid   = threadIdx.x;                                                                    //  thread  id    

//	int   offrow =( bid  > 0 ) ? (blockIdx.x - 1)*blockDim.x + threadIdx.x  : 0;                   // ��һ�����λ�ƾ���ƫ��ֵ  �˴����޸�  wong    2016/06/24

	int    offrow = 0;

	if (bid  > 0 && bid < gridDim.x - 1 && tid < blockDim.x-1 )   {
	
		    offrow = (blockIdx.x - 1)*blockDim.x + threadIdx.x;
	
	} 




	if (bid > 0 && bid < gridDim.x - 1 && tid < blockDim.x - 1 && (abs(disOutputCuda[offset]) > 12))  {

		singularOutputCuda[offset] = disOutputCuda[offrow];

	}

	else  {

		singularOutputCuda[offset] = disOutputCuda[offset];

	}


}


//λ�Ƶ���       changed   by  wong    2016/5/18

__global__   void   displace_add_cuda(Complex*singularOutputCuda, Complex*addOutputCuda)   {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                               // ���λ�ƾ���ƫ��ֵ

	int    bid   = blockIdx.x;                                                          // block   id

	int    tid   = threadIdx.x;                                                         // thread  id   

	int   offrow = (bid >0 ) ? ( (blockIdx.x - 1)*blockDim.x + threadIdx.x)  :0 ;       // ��һ�����λ�ƾ���ƫ��ֵ

	int   nextoff =  (blockIdx.x + 1)*blockDim.x + threadIdx.x;


	Complex  sum = 0.0;




	if (bid > 0)  {

		       //new  changed  

		for (int i = 0; i < bid; i++)   {

			int  off = i*blockDim.x + threadIdx.x;


			sum = sum + singularOutputCuda[off];

		}


		addOutputCuda[offset] = singularOutputCuda[offset] + sum;


	}

	else   {

		addOutputCuda[offset] = singularOutputCuda[offset];

	}







//	if (bid < gridDim.x - 1)     {
	
	    
//		addOutputCuda[nextoff] = singularOutputCuda[nextoff] + singularOutputCuda[offset];
	
	
//	}








}



//������չN-1�У���������

__global__   void   extend_data_cuda(Complex*addOutputCuda, Complex*extendOutputCuda)   {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                        // ���λ�ƾ���ƫ��ֵ

	int    bid   = blockIdx.x;                                                  // block   id

	int    tid   = threadIdx.x;                                                 // thread  id   


	if (tid<N - 1)  {

		int   add_base = blockIdx.x *(blockDim.x - (N - 1));

		extendOutputCuda[offset] = addOutputCuda[add_base];                    //  extend  primites

	}

	else
	{

		int   extoff = blockIdx.x *(blockDim.x - (N - 1)) + threadIdx.x - (N - 1);

		extendOutputCuda[offset] = addOutputCuda[extoff];

	}

}


//���ۼ�ƽ��   

__global__ void  smooth_filter_cuda(Complex*extendOutputCuda, Complex* smoothOutputCuda)   {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                        // ���λ�ƾ���ƫ��ֵ

	int   extbase = blockIdx.x*(blockDim.x + N - 1) + threadIdx.x;              // ��ַ

	int    bid = blockIdx.x;                                                    // block   id

	int    tid = threadIdx.x;                                                   // thread  id  


	Complex   sum = 0;


	for (int i = extbase; i < extbase + N; i++)  {


		Complex  temp = *(extendOutputCuda + i);

		sum = sum + temp;


	}

	smoothOutputCuda[offset] = sum / N;

}




__global__  void   timeField_filter_cuda(const Complex* smoothOutputCuda, const float* param,  const int  steps, Complex* timeFilterOutputCuda)    {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                        // ���λ�ƾ���ƫ��ֵ


	int    bid = blockIdx.x;                                                    // block   id

	int    tid = threadIdx.x;                                                   // thread  id     

	Complex  sum_temp = 0;

	float    coeff   = 0;

	for (int i = 0; i <= bid; i++)   {

		if ((bid - i) < steps)

			coeff = param[bid - i];

		else

			coeff = param[0];


		sum_temp += smoothOutputCuda[i*blockDim.x + threadIdx.x] * coeff;


	}

	timeFilterOutputCuda[offset] = sum_temp;

}






bool    CudaMain::isAvailable()  {

	int   count = 0;

	printf("Start to detecte devices.........\n");                   //  ��ʾ��⵽���豸��

	cudaGetDeviceCount(&count);                                     //   �������������ڵ���1.0���豸��

	if (count == 0){

		fprintf(stderr, "There is no device.\n");

		return false;

	}


	printf("%d device/s detected.\n", count);                      //   ��ʾ��⵽���豸��


	int i;

	for (i = 0; i < count; i++){                                  //  ������֤��⵽���豸�Ƿ�֧��CUDA

		cudaDeviceProp prop;

		if (cudaGetDeviceProperties(&prop, i) == cudaSuccess) {  //  ����豸���Բ���֤�Ƿ���ȷ

			if (prop.major >= 1)                                 //  ��֤�����������������������ĵ�һλ���Ƿ����1

			{
				printf("Device %d: %s supports CUDA %d.%d.\n", i + 1, prop.name, prop.major, prop.minor);//��ʾ��⵽���豸֧�ֵ�CUDA�汾
				break;


			}
		}
	}

	if (i == count) {                                         //   û��֧��CUDA1.x���豸
		fprintf(stderr, "There is no device supporting CUDA 1.x.\n");
		return false;
	}

	cudaSetDevice(i);                                       //    �����豸Ϊ�����̵߳ĵ�ǰ�豸

	return true;

}





CudaMain::CudaMain()  {

	


	cpu_inputMat      = NULL;
	
	cpu_SplineOutMat  = NULL ;

	cpu_RadonMat      = NULL;

	cpu_WaveRate      = 0  ;

	mallocFlag        = false;

	cpu_config        = new   ConfigParam ;

	cpu_disMat        = NULL;



//	memset(cpu_config, 0, sizeof(cpu_config));




	inputMat         = NULL;

	zeroFilterMat    = NULL;

	frontFilterMat   = NULL;

	disOutput        = NULL;

	bandfilterParam  = NULL;

	lowfilterParam   = NULL;

	matchfilterParam = NULL;

	lowFrontMat      = NULL;

	lowBackMat       = NULL;

	singularOutputCuda = NULL;

	addOutputCuda      = NULL;

	extendOutputCuda   = NULL;


	radonIn          = NULL;

	radonOut         = NULL;


}




CudaMain :: ~CudaMain()  {

	freeMem(); 



}



void   CudaMain::inputConfigParam( ConfigParam*config) {



	cpu_config = config;


}



void  CudaMain::inputRfData(const EInput& in) {     //�������ݵ�cpu_inputMat��

	float* input = in.pDatas;


	for (int i = 0; i < cpu_inputMat->rows; i++)
	{
		for (int j = 0; j < cpu_inputMat->cols; j++)
		{
			*(static_cast<float*>(static_cast<void*>(CV_MAT_ELEM_PTR(*cpu_inputMat, i, j)))) = input[i * cpu_inputMat->cols + j];
		}
	}


}




void  CudaMain::getbandFilterParam(std::string paramFileName) {

	if (paramFileName.size() == 0)
	{
		exit(1);
	}

	std::fstream paramFile(paramFileName.c_str());

	if (!paramFile)
	{
		exit(1);
	}

	float tmp;

	std::string str;


	cpu_bandfilterParam.clear();

	while (!paramFile.eof())
	{
		paramFile >> tmp;
		cpu_bandfilterParam.push_back(tmp);
	}
	paramFile.close();



}


void   CudaMain::getlowFilterParam(std::string paramFileName) {

	if (paramFileName.size() == 0)
	{
		exit(1);
	}

	std::fstream paramFile(paramFileName.c_str());

	if (!paramFile)
	{
		exit(1);
	}

	float tmp;

	std::string str;


	cpu_lowfilterParam.clear();

	while (!paramFile.eof())
	{
		paramFile >> tmp;
		cpu_lowfilterParam.push_back(tmp);
	}
	paramFile.close();


}



void  CudaMain::getmatchFilterParam(std::string paramFileName) {

	if (paramFileName.size() == 0)
	{
		exit(1);
	}

	std::fstream paramFile(paramFileName.c_str());

	if (!paramFile)
	{
		exit(1);
	}

	float tmp;

	std::string str;


	cpu_matchfilterParam.clear();

	while (!paramFile.eof())
	{
		paramFile >> tmp;
		cpu_matchfilterParam.push_back(tmp);
	}
	paramFile.close();

}











void  CudaMain::mallocMem(void)  {

	mallocMats();

	mallocGPUMem();

	

}



void CudaMain::freeMem(void)  {

	freeMats();
   
	deleteGPUMem();
}





void   CudaMain::mallocGPUMem() {



	int  MatRows = cpu_config->shearFrameLineNum;

	int  MatCols = cpu_config->sampleNumPerLine ;

	int windowHW = cpu_config->windowHW;

	int maxLag   = cpu_config->maxLag;

	int step     = cpu_config->step;


	int interpnum  = cpu_config->fitline_pts;

	int iBPParaLen = 40;                                                      // bandpassfilter�ĳ��ȣ�

	iBPParaLen     = (iBPParaLen > cpu_bandfilterParam.size()) ? iBPParaLen : cpu_bandfilterParam.size();


	int iLPParaLen = 40;                                                      // lowpassfilter�ĳ��ȣ�

	iLPParaLen     = (iBPParaLen > cpu_lowfilterParam.size()) ? iBPParaLen : cpu_lowfilterParam.size();


	int iMHParaLen = 40;                                                      // matchfilter�ĳ��ȣ�

	iMHParaLen    = (iBPParaLen > cpu_matchfilterParam.size()) ? iBPParaLen : cpu_matchfilterParam.size();






	if (MatRows == 0 || MatCols == 0)
	{

		printf("  row  and col  is zero! call InputConfigParas first!\n");
		return;

	}

	cudaError cudaStatus = cudaSetDevice(0);                                 // 0��titan�Կ�

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		return;
	}



	int  multiWin = 2;                                                      //  �󴰿ڶ�С���ڵı���

	int cxorrLines = MatRows - 1;                                           //  λ�ƾ������ɨ������Ŀ        299

	int iOutRows = (MatCols - multiWin*windowHW) / step;                    //  λ�ƾ��������Ҫƥ��Ķ���     799 

	int extRows = iOutRows + N - 1;                                         //  ��չ����  799+100-1

	cudaMalloc(&disOutput, cxorrLines *iOutRows* sizeof(Complex));          //  λ�ƾ���GPU�ڴ����


//	cudaMalloc(&templateMatShare, cxorrLines *iOutRows* sizeof(templateMat));       //ģ�������GPUȫ���ڴ����


//	cudaMalloc(&objectMatShare, cxorrLines *iOutRows* sizeof(objectMat));         //Ŀ�������GPUȫ���ڴ����


//	cudaMalloc(&resultMatShare, cxorrLines *iOutRows* sizeof(resultMat));        //���������GPUȫ���ڴ����






	cudaMalloc(&singularOutputCuda, cxorrLines *iOutRows* sizeof(Complex)); // ȥ���������GPU�ڴ����


	cudaMalloc(&addOutputCuda, cxorrLines *iOutRows* sizeof(Complex));      // λ�Ƶ�����GPU�ڴ����


	cudaMalloc(&extendOutputCuda, cxorrLines *extRows* sizeof(Complex));     // ��չ������GPU�ڴ����



	cudaMalloc(&inputMat, MatRows * MatCols * sizeof(Complex));             //   ���������GPU�϶�Ӧ���ڴ棻


	cudaMalloc(&zeroFilterMat, MatRows * MatCols * sizeof(Complex));       //   ��ͨ����λ�˲������GPU�ڴ���䣻


	cudaMalloc(&frontFilterMat, MatRows * MatCols * sizeof(Complex));     //  ��ͨ����λ���˲���GPU�ڴ����



	cudaMalloc(&lowBackMat, cxorrLines * iOutRows * sizeof(Complex));       //   ��ͨ����λ�˲������GPU�ڴ���䣻


	cudaMalloc(&lowFrontMat, cxorrLines * iOutRows * sizeof(Complex));     //  ��ͨ����λ���˲���GPU�ڴ����

	


	cudaMalloc(&bandfilterParam, iBPParaLen * sizeof(float));                // iBPParaLen�˲�������40


	cudaMalloc(&lowfilterParam, iLPParaLen * sizeof(float));                // iLPParaLen�˲�������40


	cudaMalloc(&matchfilterParam, iMHParaLen * sizeof(float));              // iMHParaLen�˲�������40



	cudaMalloc(&fit_IN, cxorrLines *iOutRows* sizeof(Complex));          //  λ�ƾ���GPU�ڴ����


	int   points = 5;


	int   strain_col = iOutRows - points + 1;

	cudaMalloc(&fit_Out, cxorrLines *strain_col* sizeof(Complex));          //  λ�ƾ���GPU�ڴ����






	int RadonInputCols      = 1961;                                     // 1961

	int RadonInputRows      = 4;                                       // 4

	cudaMalloc(&radonIn, sizeof(float) * RadonInputCols * RadonInputRows);                //�����任GPU����

	cudaMalloc(&radonOut, sizeof(float) * RadonInputCols * (RadonInputCols - 1));        //�����任GPU���  


	mallocFlag             = true;




}





void  CudaMain::deleteGPUMem()  {


	if (inputMat != NULL)
	{
		cudaFree(inputMat);

		inputMat = NULL;
	}

	
	if (zeroFilterMat != NULL)
	{
		cudaFree(zeroFilterMat);
		zeroFilterMat = NULL;
	}


	if (frontFilterMat != NULL)
	{
		cudaFree(frontFilterMat);
		frontFilterMat = NULL;
	}


	if (lowBackMat != NULL)
	{
		cudaFree(lowBackMat);
		lowBackMat = NULL;
	}


	if (lowFrontMat != NULL)
	{
		cudaFree(lowFrontMat);
		lowFrontMat = NULL;
	}




	if (disOutput != NULL)
	{
		cudaFree(disOutput);
		disOutput = NULL;
	}




	if (singularOutputCuda != NULL)
	{
		cudaFree(singularOutputCuda);

		singularOutputCuda = NULL;
	}


	if (addOutputCuda != NULL)
	{
		cudaFree(addOutputCuda);

		addOutputCuda = NULL;
	}


	if (extendOutputCuda != NULL)
	{
		cudaFree(extendOutputCuda);

		extendOutputCuda = NULL;
	}







	if (bandfilterParam != NULL)
	{
		cudaFree(bandfilterParam);
		bandfilterParam = NULL;
	}

	
	if (lowfilterParam != NULL)
	{
		cudaFree(lowfilterParam);
		lowfilterParam = NULL;
	}



	if (matchfilterParam != NULL)
	{
		cudaFree(matchfilterParam);
		matchfilterParam = NULL;
	}






	if (radonIn != NULL)
	{
		cudaFree(radonIn);
	}

	if (radonIn != NULL)
	{
		cudaFree(radonIn);
	}


	cudaDeviceReset();

	mallocFlag = false;


}




void  CudaMain::mallocMats() {


	cpu_inputMat    =   cvCreateMat(cpu_config->shearFrameLineNum, cpu_config->sampleNumPerLine, CV_32FC1);         //�������

	int  MatRows    = cpu_config->shearFrameLineNum;

	int  MatCols    = cpu_config->sampleNumPerLine;

	int windowHW    = cpu_config->windowHW;

	int maxLag      = cpu_config->maxLag;

	int step        = cpu_config->step;


	int  multiWin   = 2;                                                    //  �󴰿ڶ�С���ڵı���

	int cxorrLines  = MatRows - 1;                                         //   λ�ƾ������ɨ������Ŀ        299

	int iOutRows    = (MatCols - multiWin*windowHW) / step;               //    λ�ƾ��������Ҫƥ��Ķ���     799 

	cpu_disMat      = cvCreateMat(cxorrLines, iOutRows, CV_32FC1);       //     λ�ƾ���   



	int  fit_point  = 5;

	
	int  fit_cols = iOutRows - fit_point + 1;

	cpu_fitMat = cvCreateMat(cxorrLines, fit_cols, CV_32FC1);                 





	cpu_SplineOutMat = cvCreateMat(1962, 4, CV_32FC1);                  //    SplineOutMat��������ڻ�ͼ���ȽϽ��  

		
	cpu_RadonMat    = cvCreateMat(1962, 4, CV_32FC1);                  //     radon������Ƚϼ�����  



	mallocFlag     = false; 
	

//	cpu_config     = (ConfigParam*)malloc(1 * sizeof(ConfigParam));     

	
//	memset(cpu_config, 0, sizeof(cpu_config));

}



void   CudaMain::freeMats() {

	if (cpu_inputMat != NULL)
	{
		cvReleaseMat(&cpu_inputMat);
		cpu_inputMat = NULL;
	}
	

	if (cpu_disMat != NULL)
	{
		cvReleaseMat(&cpu_disMat);
		cpu_disMat = NULL;
	}
	

	if (cpu_SplineOutMat != NULL)
	{
		cvReleaseMat(&cpu_SplineOutMat);
		cpu_SplineOutMat = NULL;
	}

	if (cpu_RadonMat != NULL)
	{
		cvReleaseMat(&cpu_RadonMat);
		cpu_RadonMat = NULL;
	}
	

	mallocFlag = NULL;


	free(cpu_config);


	cpu_config = NULL;

	  
}








//this   threads  number  of  this   module    is  8192  .not  suitable  for   this   GTX560 TI  GPU  platform  

CvMat*  CudaMain::bandpassFilt_cuda(CvMat* rawMat)  {


	Complex* h_MatData = (Complex*)rawMat->data.fl;

	cudaMemsetAsync(frontFilterMat, 0, sizeof(Complex)*rawMat->cols*rawMat->rows);

	cudaMemcpyAsync(zeroFilterMat, h_MatData, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyHostToDevice);    //����CPU��RF���ݵ�GPU

	int steps = cpu_bandfilterParam.size();

	cudaMemcpyAsync(bandfilterParam, &cpu_bandfilterParam[0], sizeof(float)*steps, cudaMemcpyHostToDevice);                  //����CPU�г�ͷ���ݵ�GPU 





	dim3 blockID, threadID;

	blockID.x  = rawMat->rows;

	threadID.x = rawMat->cols;

	cudaThreadSynchronize();

	Bandpass_front_1 <<<blockID, threadID >> >(zeroFilterMat, rawMat->cols, bandfilterParam, steps, frontFilterMat);

	cudaThreadSynchronize();


	cudaMemcpy(zeroFilterMat, frontFilterMat, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyDeviceToDevice);


	Bandpass_back_1 << <blockID, threadID >> >(zeroFilterMat, rawMat->cols, bandfilterParam, steps, frontFilterMat);


	cudaThreadSynchronize();

	   
	cudaFree(bandfilterParam);

	cudaMemcpy(h_MatData, frontFilterMat, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

	cudaFree(zeroFilterMat);

	cudaFree(frontFilterMat);


	SaveDataFile("bpfilt.dat", rawMat);


	return rawMat;


}



//worker  for  this   platform   ,1024   threads   limited .  change   by  wong     2016/6/12

CvMat*  CudaMain::bandpassFilt_1024_cuda(CvMat* rawMat)  {


	Complex* h_MatData = (Complex*)rawMat->data.fl;

	cudaMemsetAsync(frontFilterMat, 0, sizeof(Complex)*rawMat->cols*rawMat->rows);

	cudaMemcpyAsync(zeroFilterMat, h_MatData, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyHostToDevice);    //����CPU��RF���ݵ�GPU

	int steps = cpu_bandfilterParam.size();

	cudaMemcpyAsync(bandfilterParam, &cpu_bandfilterParam[0], sizeof(float)*steps, cudaMemcpyHostToDevice);                  //����CPU�г�ͷ���ݵ�GPU 


	dim3 blockID, threadID;

	blockID.x = rawMat->rows*8;                           //changed   by  wong  


//	blockID.x = rawMat->rows * 8*2;


	threadID.x = rawMat->cols/8;                      //changed  by  wong 

//	threadID.x = rawMat->cols / 16;





	cudaThreadSynchronize();

	Bandpass_front_1024 << <blockID, threadID >> >(zeroFilterMat, rawMat->cols, bandfilterParam, steps, frontFilterMat);

	cudaThreadSynchronize();


	//test  for  line 2 

//	cudaMemcpy(h_MatData, frontFilterMat, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

//	SaveDataFile("front_1024.dat", rawMat);


	cudaMemcpy(zeroFilterMat, frontFilterMat, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyDeviceToDevice);


	Bandpass_back_1024 << <blockID, threadID >> >(zeroFilterMat, rawMat->cols, bandfilterParam, steps, frontFilterMat);



	cudaThreadSynchronize();


	cudaFree(bandfilterParam);

	cudaMemcpy(h_MatData, frontFilterMat, sizeof(Complex)*rawMat->cols*rawMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

	cudaFree(zeroFilterMat);

	cudaFree(frontFilterMat);


	//SaveDataFile("back_1024.dat", rawMat);


	return rawMat;
 






}










void  CudaMain::zeroFilter_cuda(CvMat* rawMat, Complex*filterOutput) {







}





void   CudaMain::computeDisplacement_cuda(CvMat* filtOutMat, int  multiWin, int winSize, int stepSize, CvMat*outputMat){

//	CvMat*outputMat = 0;

	int     WinNum    = (filtOutMat->cols - multiWin*winSize) / stepSize;       //  һάλ�ƾ���

	Complex* hInput   = (Complex*)filtOutMat->data.fl;                         //   ����λ�ã�

	Complex*hOutput  = (Complex*)outputMat->data.fl;                        //   ����λ�ã�


	cudaMemcpy(inputMat, hInput, filtOutMat->cols*filtOutMat->rows*sizeof(Complex), cudaMemcpyHostToDevice);   //  CPU-GPU

	dim3 dBlock;

	dim3 dThread;

	dBlock.x = filtOutMat->rows - 1;                                 // ����������� ,����        299

//	dBlock.x = 200;                                                 //just   test   wong    2016/06/15

	dThread.x = WinNum;                                             // ����������� , �߳���      799


//	__device__   Complex*templateMatShare;                          //   ģ���ڴ���GPU����         ���Ǿֲ�����                  


//	__device__   Complex*objectMatShare;                           //    Ŀ���ڴ���GPU����         ���Ǿֲ�����


//	__device__   Complex*resultMatShare;                           //    ƥ������GPU����         ���Ǿֲ�����




	templateMat*templateMatShare;                                 //   ģ���ڴ���GPU���� 


	objectMat* objectMatShare;                                   //    Ŀ���ڴ���GPU���� 



	resultMat*resultMatShare;                                   //    ƥ������GPU���� 



	Complex*      min;


	Complex*      max;

	int*          max_location;


	Complex*      displacement;








	cudaMalloc(&templateMatShare, dBlock.x*dThread.x* sizeof(templateMat));             //ģ�������GPUȫ���ڴ����


	cudaMalloc(&objectMatShare,  dBlock.x*dThread.x* sizeof(objectMat));               //Ŀ�������GPUȫ���ڴ����


	cudaMalloc(&resultMatShare,  dBlock.x*dThread.x* sizeof(resultMat));             //���������GPUȫ���ڴ����



	cudaMalloc(&min, dBlock.x*dThread.x* sizeof(Complex));                           // min��GPUȫ���ڴ����


	cudaMalloc(&max, dBlock.x*dThread.x* sizeof(Complex));                          // max��GPUȫ���ڴ����


	cudaMalloc(&max_location, dBlock.x*dThread.x* sizeof(int));                     // max_location��GPUȫ���ڴ����


	cudaMalloc(&displacement, dBlock.x*dThread.x* sizeof(Complex));                // max_location��GPUȫ���ڴ����



	
	//��λ�ƾ���  

	displacement_api_cuda << < dBlock, dThread >> >   (inputMat, filtOutMat->rows, filtOutMat->cols, multiWin, winSize, stepSize, templateMatShare, objectMatShare, resultMatShare, min, max, max_location, displacement);

	cudaThreadSynchronize();

	//test  for   displace      changed  by  wong   2016/06/20

	cudaMemcpy(hOutput, displacement, sizeof(Complex)*outputMat->cols*outputMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

	SaveDataFile("weiyi_gpu.dat", outputMat);




	cudaFree(templateMatShare);

	cudaFree(objectMatShare);

	cudaFree(resultMatShare);

	cudaFree(min);

	cudaFree(max);

	cudaFree(max_location);









	//ȥ����                                   

	remove_singular_cuda << <dBlock, dThread >> >   (displacement, singularOutputCuda);

	cudaThreadSynchronize();


	//test  for   displace      changed  by  wong   2016/06/20

//	cudaMemcpy(hOutput, singularOutputCuda, sizeof(Complex)*outputMat->rows*outputMat->cols, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

//	 SaveDataFile("sigular_gpu.dat", outputMat);





	//λ�Ƶ���                 

	displace_add_cuda << <dBlock, dThread >> >  (singularOutputCuda, addOutputCuda);

	cudaThreadSynchronize();


	//test  for   add      changed  by  wong   2016/06/20

//	cudaMemcpy(hOutput, addOutputCuda, sizeof(Complex)*outputMat->rows*outputMat->cols, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

//    SaveDataFile("add_gpu.dat", outputMat);






	//ǰN-1�в�0    

	int  ext_threads = dThread.x + N - 1;

	extend_data_cuda << < dBlock, ext_threads >> > (addOutputCuda, extendOutputCuda);

	cudaThreadSynchronize();

	cudaFree(addOutputCuda);

	//ƽ���˲�  

	smooth_filter_cuda << <dBlock, dThread >> >   (extendOutputCuda, disOutput);

	cudaThreadSynchronize();

	cudaFree(extendOutputCuda);


	//test  for   smmoth      changed  by  wong   2016/06/20

//	cudaMemcpy(hOutput, disOutput, sizeof(Complex)*outputMat->rows*outputMat->cols, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

///	SaveDataFile("smooth_gpu.dat", outputMat);








	//ʱ���˲���ƥ���˲���50Hz��ǿ     ���� param, iParaLen, steps ʹ�ó����ڴ� 

	int steps = cpu_matchfilterParam.size();

	cudaMemcpyAsync(matchfilterParam, &cpu_matchfilterParam[0], sizeof(float)*steps, cudaMemcpyHostToDevice);             //����CPU�г�ͷ���ݵ�GPU 


	timeField_filter_cuda << <dBlock, dThread >> > (disOutput, matchfilterParam,  steps, singularOutputCuda);

	cudaThreadSynchronize();

	cudaFree(disOutput);

	//��GPU������CPU�ڴ�


	cudaMemcpy(hOutput, singularOutputCuda, dBlock.x  * dThread.x*sizeof(Complex), cudaMemcpyDeviceToHost);   //  GPU-CPU


	cudaFree(singularOutputCuda);

	
	//test  for   smmoth      changed  by  wong   2016/06/20

    SaveDataFile("time_gpu.dat", outputMat);


}






void   CudaMain::zeroDisplacement_cuda(CvMat* inputMat, int  multiWin, int winSize, int stepSize, Complex*disOutput){





}


//changed   by  wong     2016/06/22         lowpass filter    size  : 299*799

//���˲�   ������

__global__ void     lowpass_front_799(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)    {


	float data_sum;

	float data_1;

	data_sum = 0.0;


	if (threadIdx.x <= iParaLen - 1)                                         //������ĿС�ڵ��ڳ�ͷ��Ŀ
	{

		for (int i = 0; i <= threadIdx.x; i++)
		{


			data_1 = *(tInput + blockIdx.x*iWidth + threadIdx.x - i);      //b(0)*x(n-0)+b(1)*x(n-1)+...+b(n)*x(0)   

			data_sum += (data_1*param[i]);

		}

		data_1 = *(tInput + blockIdx.x * iWidth);                          // x(0)


		for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
		{
			data_sum += (data_1*param[j]);                                 //b(n+1)*x(0)+...+b(nb-2)*x(0)
		}

		*(tOutPut + blockIdx.x * iWidth + threadIdx.x) = data_sum;



	}
	else                                                                  //������Ŀ���ڳ�ͷ��Ŀ            
	{
		//data_1 = (tInput + blockIdx.x*iWidth + blockIdx.y - threadIdx.x)->x;
		for (int i = 0; i <= iParaLen - 1; i++)
		{

			data_1 = *(tInput + blockIdx.x*iWidth + threadIdx.x - i);   //b(0)*x(n-0)+b(1)*x(n-1)+...+b(nb-2)*x(n-(nb-2))  

			data_sum += (data_1*param[i]);

		}

		*(tOutPut + blockIdx.x * iWidth + threadIdx.x) = data_sum;

	}




}



   //changed   by   wong      2016/06/22        zero-phase  filter    size  :  299*799

  // ���˲� ��������     


__global__  void   lowpass_back_799(Complex* tInput, int iWidth, float* param, int iParaLen, Complex* tOutPut)   {


	

	float data_1;

	float data_sum;

	data_sum = 0.0;



	if (threadIdx.x <= iParaLen - 1)   {                                //  ���ݳ���С�ڵ����˲�����ͷ����


		for (int i = 0; i <= threadIdx.x; i++)
		{


			data_1 = *(tInput + blockIdx.x*iWidth + iWidth - 1 - threadIdx.x + i);      //

			data_sum += (data_1*param[i]);

		}


		data_1 = *(tInput + blockIdx.x * iWidth + iWidth - 1);                        //  x(N-1) 


		for (int j = threadIdx.x + 1; j <= iParaLen - 1; j++)
		{

			data_sum += (data_1*param[j]);                                            // b(n+1)*x(N-1)+...+b(nb-1)*x(N-1) 

		}


		*(tOutPut + blockIdx.x * iWidth + iWidth - 1 -threadIdx.x) = data_sum;                 // y(n)

	}

	else    {                                                                       //���ݳ��ȴ����˲�����ͷ����         


		for (int i = 0; i <= iParaLen - 1; i++)
		{
			data_1 = *(tInput + blockIdx.x*iWidth + iWidth - 1 - threadIdx.x + i);

			data_sum += (data_1*param[i]);                                         //  y(N-1-n) = b(0)*x(N-1-n+0) +b(1)*x(N-1-n+1)+...+b(nb-1)*x(N-1-n+nb-1)

		}

		*(tOutPut + blockIdx.x * iWidth + iWidth - 1 - threadIdx.x) = data_sum;




	}



}










	




CvMat*  CudaMain::lowpassFilt_799_cuda(CvMat* disMat)  { 


	Complex* h_MatData = (Complex*)disMat->data.fl;

	cudaMemsetAsync(lowBackMat, 0, sizeof(Complex)*disMat->rows*disMat->cols);

	cudaMemcpyAsync(lowFrontMat, h_MatData, sizeof(Complex)*disMat->rows*disMat->cols, cudaMemcpyHostToDevice);           //����CPU��RF���ݵ�GPU

	int steps = cpu_lowfilterParam.size();

	cudaMemcpyAsync(lowfilterParam, &cpu_lowfilterParam[0], sizeof(float)*steps, cudaMemcpyHostToDevice);                  //����CPU�г�ͷ���ݵ�GPU 





	dim3 blockID, threadID;

	blockID.x = disMat->rows;

	threadID.x = disMat->cols;


	lowpass_front_799 << <blockID, threadID >> >(lowFrontMat, disMat->cols, lowfilterParam, steps, lowBackMat);

	cudaThreadSynchronize();

	//test   for  lower   begin

	cudaMemcpy(h_MatData, lowBackMat, sizeof(Complex)*disMat->cols*disMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

	SaveDataFile("799_lower.dat", disMat);

	//test  end 

	cudaMemcpy(lowFrontMat, lowBackMat, sizeof(Complex)*disMat->rows*disMat->cols, cudaMemcpyDeviceToDevice);


	lowpass_back_799 << <blockID, threadID >> >(lowFrontMat, disMat->cols, lowfilterParam, steps, lowBackMat);


	cudaThreadSynchronize();


	cudaFree(lowfilterParam);

	cudaMemcpy(h_MatData, lowBackMat, sizeof(Complex)*disMat->cols*disMat->rows, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU

	cudaFree(lowFrontMat);

	cudaFree(lowBackMat);


	SaveDataFile("lowpass_gpu.dat", disMat);



	const   char* file_pwd = "lowpass_gpu.bmp";


	MakeImage(disMat, file_pwd);

	return disMat;




}


__device__  void    fitLine_cv_func(Complex*xx_tmp, Complex*yy_tmp, Complex* result)   {


	Complex xmean = 0.0f;

	Complex ymean = 0.0f;

	for (int i = 0; i < 5; i++)
	{
		xmean += xx_tmp[i];

		ymean += yy_tmp[i];

	}


	xmean /= 5;

	ymean /= 5;


	Complex sumx2 = 0.0f;

	Complex sumxy = 0.0f;

	for (int i = 0; i < 5; i++)
	{

		sumx2 += (xx_tmp[i] - xmean) * (xx_tmp[i] - xmean);

		sumxy += (yy_tmp[i] - ymean) * (xx_tmp[i] - xmean);

	}


	*result = (Complex)(sumxy / sumx2);

}





//changed   by  wong     2016/07/04
__global__  void  fitLine_L2_cuda(Complex*strain_IN, Complex*xx_IN,  Complex*strainOut)   {

	int   offset = blockIdx.x *blockDim.x + threadIdx.x;                        // ���λ�ƾ���ƫ��ֵ


	int    bid = blockIdx.x;                                                    // block   id

	int    tid = threadIdx.x;                                                   // thread  id     


	int    act_off = blockIdx.x *(blockDim.x + 5 - 1) + threadIdx.x;  // input



	Complex   xx_tmp[5];

	Complex  yy_tmp[5];


	for (int i = 0; i < 5; i++)  {

		xx_tmp[i] = xx_IN[act_off + i];

		yy_tmp[i] = strain_IN[act_off + i];


	}


	fitLine_cv_func(xx_tmp, yy_tmp, &strainOut[offset]);


}






//  changed  by  wong      2016/07/01

void  CudaMain::strainCalculate_cuda(CvMat*disMat,    CvMat* fitMat)  {


	Complex* h_MatData = (Complex*)disMat->data.fl;


	Complex* out_MatData = (Complex*)fitMat->data.fl;


	cudaMemcpyAsync(fit_IN, h_MatData, sizeof(Complex)*disMat->rows*disMat->cols, cudaMemcpyHostToDevice);           //����CPU��RF���ݵ�GPU


	int   fit_points = 5;


	dim3 blockID, threadID;

	blockID.x = disMat->rows;

	threadID.x = disMat->cols - fit_points +1;


//	Complex* point_num;


//	cudaMalloc(&point_num,  sizeof(Complex));             //  λ�ƾ���GPU�ڴ����


	//XXֵ����

	int   xx_rows = disMat->rows;

	int  xx_cols  = disMat->cols;


	CvMat*    xx_mat = cvCreateMat(xx_rows, xx_cols, CV_32FC1);


	   
	for (int i = 0; i < xx_rows; i++)   {

		for (int j = 0; j < xx_cols; j++)  {
		
		
			*(static_cast<float*>(static_cast<void*>(CV_MAT_ELEM_PTR(*xx_mat, i, j)))) = j*fit_points;
				
		}
	
	}


	Complex* xx_IN  ;

    cudaMalloc(&xx_IN, sizeof(Complex)*xx_rows*xx_cols);             //  λ�ƾ���GPU�ڴ����


	Complex* xx_Data = (Complex*)xx_mat->data.fl;


	cudaMemcpyAsync(xx_IN, xx_Data, sizeof(Complex)*xx_mat->rows*xx_mat->cols, cudaMemcpyHostToDevice);



	fitLine_L2_cuda << <blockID, threadID >> >  (fit_IN, xx_IN,  fit_Out);


	cudaMemcpy(out_MatData, fit_Out, sizeof(Complex)*fitMat->rows*fitMat->cols, cudaMemcpyDeviceToHost);   //����GPU��������ݵ�	CPU




	cudaFree(fit_IN);

	cudaFree(xx_IN);

	cudaFree(fit_Out);


	SaveDataFile("fitLine_gpu.dat", fitMat);







}




void  CudaMain::ImagePostProc(IplImage *strImage, const char *filename, const CvPoint &start, const CvPoint &end)
{

	const char * gray_file = "strain_gpu_gray.bmp";


	{
		IplImage *pimgStrain = cvCreateImage(cvGetSize(strImage), strImage->depth, 3);

		cvCvtColor(strImage, pimgStrain, CV_GRAY2BGR);

		cvSaveImage(gray_file, pimgStrain);

		cvReleaseImage(&pimgStrain);

	}

	{

		IplImage *pImage = cvLoadImage(gray_file, 0);

		IplImage *pimgStrain = cvCreateImage(cvGetSize(pImage), pImage->depth, 3);

		pimgStrain = cvCreateImage(cvGetSize(pImage), pImage->depth, 3);


		//ͼ����ǿ ��1
		// ������� [0,0.5] �� [0.5,1], gamma=1  ͼ����ǿ
		ImageAdjust(pImage, pImage, 0, 0.5, 0, 0.5, 0.6);// Y����mapped to bottom and top of dst	

		//cvSaveImage("res\\ImageAdjust.bmp", image);//������ǿЧ��ͼ

		//ͼ����ǿ ��2 Ч������
		//ImageStretchByHistogram(image, image);//ͼ����ǿ: �����ȫ��������
		//cvSaveImage("res\\ImageStretchByHistogram.bmp", image);

		//ͼ����ǿ ��3 Ч������
		//ImageStretchByHistogram2(image, image);//ͼ����ǿ: �����ȫ��������
		//cvSaveImage("res\\ImageStretchByHistogram2.bmp", image);

		cvNot(pImage, pImage);//�ڰ���ɫ��ת

		//cvSaveImage("res\\cvNot.bmp", image);//�ڰ�ͼ
		cvCvtColor(pImage, pimgStrain, CV_GRAY2BGR);//ͼ��ת����BGR


		ChangeImgColor(pimgStrain);


		cvLine(pimgStrain, start, end, CV_RGB(255, 0, 0), 2, CV_AA, 0);   //����


		cvSaveImage(filename, pimgStrain);


		//�ͷ���Դ
		cvReleaseImage(&pImage);

		cvReleaseImage(&pimgStrain);

	}

}










//////////////////////////////////////////////////////////////////////////
// �����任
// pmatDisplacement,   rows: disp;  cols: time-extent( lines)
//     ��,��ʾһ����, Ҳ����ʱ�� ��
//     ��,��ʾӦ���ֵ
//////////////////////////////////////////////////////////////////////////

void   CudaMain::RadonSum(const CvMat *pmatDisplacement, CvMat **ppmatRodan) {


	int xstart          = 0;

	int xend            = pmatDisplacement->rows;                      //159

	int t               = pmatDisplacement->cols;                     // time extent        //298 

	CvMat *pmatRodan    = cvCreateMat(t - 1, t, pmatDisplacement->type);

	cvZero(pmatRodan);

	int tstart          = 0;

	int tend            = 0;

	int dx              = 0;

	float dt            = 0.0f;

	float c             = 0.0f;


	for (tstart = 0; tstart < t - 1; tstart++)
	{

		for (tend = tstart + 1; tend < t; tend++)
		{

			c = (float)(xend - xstart) / (tend - tstart);                     //k

			for (dx = xstart; dx < xend; dx++)
			{

				dt = tstart + (dx - xstart) / c;                             //

				CV_MAT_ELEM(*pmatRodan, float, tstart, tend) = CV_MAT_ELEM(*pmatRodan, float, tstart, tend)
					+ CV_MAT_ELEM(*pmatDisplacement, float, dx, (int)dt);

			}
		}
	}


	*ppmatRodan = pmatRodan;






}









//�����ֶμ���
void  CudaMain::RadonProcess2(CvPoint &s, CvPoint &e, ConfigParam*config, const CvRect &sub_rc, const CvMat &matStrain)
{

	int  radon_num = config->radon_num;                    // 3
	 

	int  radon_step = config->radon_step;                  // 20



	int  intpl_multiple = 1;                               // ��ֵ��������������任   



	std::vector<RadonParam> array_params;



	for (int i = 0; i < radon_num; i++)                      //3
	{


		RadonParam param;

		param.rc.x = sub_rc.x;

		param.rc.y = sub_rc.y + i*radon_step;

		param.rc.width = sub_rc.width;

		param.rc.height = sub_rc.height;


		CvMat *pmatSub = cvCreateMatHeader(param.rc.height-1, param.rc.width-1, matStrain.type);


		cvGetSubRect(&matStrain, pmatSub, cvRect(param.rc.x, param.rc.y, param.rc.width-1, param.rc.height-1));


		CvMat *pmatRadon = 0;


		CvMat *pmatMultiple = cvCreateMat(pmatSub->rows, pmatSub->cols * intpl_multiple, pmatSub->type);


		cvResize(pmatSub, pmatMultiple);


		RadonSum(pmatMultiple, &pmatRadon);


		double  min_val;


		double  max_val;


		CvPoint min_loc;


		CvPoint max_loc;


		cvMinMaxLoc(pmatRadon, &min_val, &max_val, &min_loc, &max_loc);


		param.pt = max_loc;


		param.xWidth = param.pt.y - param.pt.x;//add by wxm


		array_params.push_back(param);


		cvReleaseMat(&pmatRadon);


		cvReleaseMat(&pmatMultiple);


		cvReleaseMatHeader(&pmatSub);


	}


	std::sort(array_params.begin(), array_params.end(), MyLessThan2());



	if (config->calc_type.compare("middle") == 0)
	{

		int size = array_params.size();


		s.x = array_params[size / 2].pt.y / intpl_multiple;


		s.y = array_params[size / 2].rc.y;


		e.x = array_params[size / 2].pt.x / intpl_multiple;


		e.y = array_params[size / 2].rc.y + array_params[size / 2].rc.height-1;

	}

	else if (config->calc_type.compare("max") == 0)
	{

		int size = array_params.size();

		s.x = array_params[0].pt.y / intpl_multiple;

		s.y = array_params[0].rc.y;


		e.x = array_params[0].pt.x / intpl_multiple;

		e.y = array_params[0].rc.y + array_params[0].rc.height-1;

	}

	else if (config->calc_type.compare("min") == 0)

	{

		int size = array_params.size();

		s.x = array_params[size - 1].pt.y / intpl_multiple;

		s.y = array_params[size - 1].rc.y;


		e.x = array_params[size - 1].pt.x / intpl_multiple;

		e.y = array_params[size - 1].rc.y + array_params[size - 1].rc.height-1;

	}

	else
	{
		//

	}










}






//�����任&����в�&����ģ��

void    CudaMain::random_proess_cuda(CvMat*fitMat, ConfigParam*config, EOutput &output)  {

	
	

		int    win_size          = config->windowHW;                                              //  ���ڴ�С


		double overlap           = (config->windowHW - config->step) / (float)config->windowHW;  //   �غ��ʣ�90%

		double sound_velocity    = config->acousVel;                                             //   �����ٶ�


		double sample_frq        = config->sampleFreqs;                                         //    ������                      

		double prf               = 1 / 300e-6;                                                  //    �ظ���


		int    dep_start         = (config->sb_x < 0) ? 0 : config->sb_x;

		int    dep_size          = (config->sb_w < 0) ? fitMat->width : config->sb_w;

		int    dep_end           = dep_start + dep_size - 1;

		int    t_start           = (config->sb_y < 0) ? 0 : config->sb_y;

		int    t_size            = (config->sb_h < 0) ? fitMat->rows : config->sb_h;

		int    t_end             = t_start + t_size - 1;


		CvMat *pmatStrainTran    = cvCreateMat(fitMat->cols, fitMat->rows, fitMat->type);       // ��strainMatת��      795*299


		cvTranspose(fitMat, pmatStrainTran);


		CvPoint                   start;

		CvPoint                    end;
		
		CvRect                     rect;


		rect.x                    = t_start;

		rect.y                    = dep_start;

		rect.width                = t_size;

		rect.height               = dep_size;


//		rect.left                = t_start;

//		rect.right               = t_end;

//		rect.top                 = dep_start;

//		rect.bottom              = dep_end;

		
#if 1
		RadonProcess2(start, end, config ,rect, *pmatStrainTran);
#endif






		double v                  = ((end.y - start.y) * win_size * (1 - overlap) * sound_velocity / sample_frq / 2)
			/ ((end.x - start.x) / prf);



		double e                  = v * v * 3;


		output.v                  = (float)v;


		output.e                  = (float)e;

		cvReleaseMat(&pmatStrainTran);


		
    // ����б��    �е�����   changed  by  wong    2016/07/08

		/*
		IplImage *strImage = cvCreateImage(cvSize(fitMat->cols, fitMat->rows), IPL_DEPTH_32F, 1);     //������ʾӦ��, �����outDataMat����ת��,���еߵ�.


		for (int i = 0; i < strImage->width; i++) {

			for (int j = 0; j < strImage->height; j++)	{


				float*	tmp = static_cast<float*>(static_cast<void*>(strImage->imageData + j * strImage->widthStep + sizeof(float) * i));  //ȡӦ��ͼ���Ӧλ��


				*tmp = 100 * CV_MAT_ELEM(*fitMat, float, i, j);

			}

		}


		    char* filename = "strain_gpu.bmp";


			ImagePostProc(strImage, filename, start, end);


			cvReleaseImage(&strImage);

   */


}












void  CudaMain::process(const EInput &input, EOutput& output) {

//	mallocMem();                                                                                 // �����ڴ�

//	inputRfData(input);                                                                          // ��ȡRF����,��cpu_inputMat 

//	inputConfigParam(config);                                                                    // ���ò��� ��cpu_config

// getFilterParam(config->bpfilt_file);                                                          // ��ȡ�˲�����ͨ��������cpu_filterParam




	   bandpassFilt_1024_cuda(cpu_inputMat);                                                     // ��ͨ�˲�       


	   int  multiWin    = 2;

	   int winSize      = cpu_config->windowHW;

	   int  stepSize    = cpu_config->step;


	   
	    computeDisplacement_cuda(cpu_inputMat, multiWin, winSize, stepSize, cpu_disMat);       //  λ�Ƽ���       
	

		lowpassFilt_799_cuda (cpu_disMat);                                                    //    ��ͨ�˲�  


	



		

		strainCalculate_cuda(cpu_disMat,   cpu_fitMat);                                       //  ֱ�����



		


		random_proess_cuda(cpu_fitMat, cpu_config, output);                                 //  �����任�����ٶȺ�����ģ��




		int   ss = 0;










	


}



