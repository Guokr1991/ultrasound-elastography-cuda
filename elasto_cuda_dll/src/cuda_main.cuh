#ifndef  _CUDA_MAIN_CUH

#define  _CUDA_MAIN_CUH

#include <opencv\cxcore.h>

#include <cuda_runtime.h>

#include <device_launch_parameters.h>

//#include "SysConfig.h"

#include <vector>


struct   EInput;

struct   EOutput;

struct   ConfigParam;


typedef float Complex;



#define    THREAD_NUM      799

#define    N               100



typedef  struct  templateMat{

	Complex  elem[100];


}  templateMat;                                         //changed   by   wong    2016/5/19




typedef  struct  objectMat{

	Complex  elem[200];


}  objectMat;                                            //changed   by   wong    2016/5/19



typedef  struct resultMat{

	Complex  elem[101];


}  resultMat;                                         //changed   by   wong    2016/5/19




class   CudaMain  {


private:

//cpu�ڴ����

	CvMat*    cpu_inputMat;                      // �������ݴ�ž���

	CvMat*    cpu_disMat;                       //  λ�ƾ���    

	CvMat*    cpu_SplineOutMat;                //  SplineOutMat��������ڻ�ͼ���ȽϽ��         

	CvMat*    cpu_RadonMat;                    //  radon������Ƚϼ�����       
    
	float     cpu_WaveRate;                    //  ���ս�������٣�



	std::vector<float> cpu_lowfilterParam;     // �������˲�����ͷ


	std::vector<float> cpu_bandfilterParam;    // �������˲�����ͷ

	
	std::vector<float> cpu_matchfilterParam;   // �������˲�����ͷ





	bool               mallocFlag;            // �ڴ�������

	ConfigParam*        cpu_config;           // ���ò���





//gpu�ڴ����

	Complex* inputMat;                       // ���������GPU����                         

	Complex* zeroFilterMat;                 // ����λ�˲������GPU�ڴ����


	Complex* frontFilterMat;               //  ����λ���˲���GPU�ڴ����\


	Complex* lowFrontMat;                 //   ����λ�˲������GPU�ڴ����


	Complex* lowBackMat;                 //   ����λ���˲���GPU�ڴ����\




	Complex* disOutput;                    //  λ�ƾ�����GPU����


//	templateMat*templateMatShare;             //   ģ���ڴ���GPU����         


//	objectMat* objectMatShare;             //    Ŀ���ڴ���GPU����         


//	resultMat*resultMatShare;              //    ƥ������GPU����        



	Complex*singularOutputCuda;            // ȥ����


	Complex*addOutputCuda;                 //λ�Ƶ���        


	Complex*extendOutputCuda;              // ǰN-1�в�0 


	float*   lowfilterParam;              // �˲���ͷ��GPU�ڴ����  


	float*   bandfilterParam;             // �˲���ͷ��GPU�ڴ���� 


	float*   matchfilterParam;            // �˲���ͷ��GPU�ڴ���� 


	float*    radonIn;                     //�����任��GPU�ڴ����

	float*    radonOut;                   //�����任��GPU�ڴ����




private:                                                                       // ˽�к���


	void mallocGPUMem(void);                                                  // ����GPU�ڴ�


	void deleteGPUMem(void);                                                 // �ͷ�GPU�ڴ�


	void mallocMats(void);                                                  // ����cpu�ڴ�


	void freeMats(void);                                                   // �ͷ�CPU�ڴ�





 virtual	CvMat* bandpassFilt_cuda(CvMat* rawMat);                      //�����������˲�����ͨ�����������Ϊ�˱��ڻ�ͼ�����棬�ȽϽ��




 virtual    CvMat* bandpassFilt_1024_cuda(CvMat* rawMat);               //�����������˲�����ͨ��1024�̣߳��������Ϊ�˱��ڻ�ͼ�����棬�ȽϽ��       



 virtual    void   zeroFilter_cuda(CvMat* rawMat,Complex*filterOutput);   //�����������˲�����ͨ���ͨ��,���������GPU��


	                                                                     // ����һάλ�ƾ����������Ϊ�˱��ڻ�ͼ�����棬�ȽϽ��            
  virtual  CvMat*computeDisplacement_cuda(CvMat* inputMat, int  multiWin, int winSize, int stepSize);


                                                                        // ����һάλ�ƾ������������GPU��
  virtual  void  zeroDisplacement_cuda(CvMat* inputMat, int  multiWin, int winSize, int stepSize, Complex*disOutput);



  virtual	CvMat* lowpassFilt_cuda(CvMat* disMat);                      //�����������˲�����ͨ�����������Ϊ�˱��ڻ�ͼ�����棬�ȽϽ��




public:                                  //���к���



	 CudaMain();


	~CudaMain();


	void  inputConfigParam( ConfigParam*config);              // ��ȡ����


	void  inputRfData(  const EInput& in);                   //  ��ȡRF����  


	void  getlowFilterParam(std::string paramFileName);      //   ��ȡ�˲�����ͷ


	void  getbandFilterParam(std::string paramFileName);   //   ��ȡ�˲�����ͷ


	void  getmatchFilterParam(std::string paramFileName);   //   ��ȡ�˲�����ͷ

	  
	void mallocMem(void);                                   //     ����CPU��GPU�ڴ�
	 
	void freeMem(void);                                     //     �ͷ��ڴ�


	float getRate(void) const {                           //    ��ȡ�ٶ�
		 
		return cpu_WaveRate; 

	}  


	bool isAvailable();                                    //  �Ƿ����GPUģ��


	void process(const EInput &input, EOutput &output);    //  ��Ҫ������


















};





























#endif