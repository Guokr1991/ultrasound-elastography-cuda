#ifndef  _CUDA_MAIN_CUH

#define  _CUDA_MAIN_CUH

#include <opencv\cxcore.h>

#include <cuda_runtime.h>

#include <device_launch_parameters.h>


#include "ImageFunc.h"

#include <vector>


struct   EInput;

struct   EOutput;

struct   ConfigParam;


typedef float Complex;



#define    THREAD_NUM      799

#define    N               100



typedef   struct    templateData  {

	Complex  elem[64];

	Complex  atom[36];


}  templateData ;



typedef   struct    objectData  {

	Complex  elem_0[64];

	Complex  elem_1[64];

	Complex  elem_2[64];

	Complex  atom[8];


} objectData ;




typedef   struct     resultData  {

	Complex  elem[64];

	Complex  atom[37];



} resultData;





typedef  struct  templateMat{



	templateData  tempData;



}  templateMat;                                         




typedef  struct  objectMat{

 

 objectData    objData;


}  objectMat;                                            



typedef  struct resultMat{

	resultData   resData;


}  resultMat;                                         





typedef struct
{
	CvRect     rc;

	CvPoint    pt;

	float      xWidth;//�������࣬ԽС����б��Խ��

} RadonParam;





struct MyLessThan2
{
	bool operator()(const RadonParam &x, const RadonParam &y)
	{
		return x.xWidth > y.xWidth;
	}
};












class   CudaMain  {


private:


	CvMat*    cpu_inputMat;                      // �������ݴ�ž���

	CvMat*    cpu_disMat;                       //  λ�ƾ���    

	CvMat*    cpu_fitMat;                       


	CvMat*    cpu_SplineOutMat;                //  SplineOutMat��������ڻ�ͼ���ȽϽ��         

	CvMat*    cpu_RadonMat;                    //  radon������Ƚϼ�����       
    
	float     cpu_WaveRate;                    //  ���ս�������٣�



	std::vector<float> cpu_lowfilterParam;     // �������˲�����ͷ


	std::vector<float> cpu_bandfilterParam;    // �������˲�����ͷ

	
	std::vector<float> cpu_matchfilterParam;   // �������˲�����ͷ





	bool                mallocFlag;            // �ڴ�������

	ConfigParam*        cpu_config;           // ���ò���




	Complex* inputMat;                       // ���������GPU����                         

	Complex* zeroFilterMat;                 // ����λ�˲������GPU�ڴ����


	Complex* frontFilterMat;               //  ����λ���˲���GPU�ڴ����\


	Complex* lowFrontMat;                 //   ����λ�˲������GPU�ڴ����


	Complex* lowBackMat;                 //   ����λ���˲���GPU�ڴ����\




	Complex* disOutput;                    //  λ�ƾ�����GPU����


	Complex*singularOutputCuda;            // ȥ����


	Complex*addOutputCuda;                 //λ�Ƶ���        


	Complex*extendOutputCuda;              // ǰN-1�в�0 


	float*   lowfilterParam;              // �˲���ͷ��GPU�ڴ����  


	float*   bandfilterParam;             // �˲���ͷ��GPU�ڴ���� 


	float*   matchfilterParam;            // �˲���ͷ��GPU�ڴ���� 



	Complex*   fit_IN;                         // Ӧ������
                           

	Complex*   fit_Out;                       //  Ӧ�����



	float*    radonIn;                     //�����任��GPU�ڴ����

	float*    radonOut;                   //�����任��GPU�ڴ����




private:                                                                       // ˽�к���


	void mallocGPUMem(void);                                                  // ����GPU�ڴ�


	void deleteGPUMem(void);                                                 // �ͷ�GPU�ڴ�


	void mallocMats(void);                                                  // ����cpu�ڴ�


	void freeMats(void);                                                   // �ͷ�CPU�ڴ�





 virtual	CvMat* bandpassFilt_cuda(CvMat* rawMat);                     




 virtual    CvMat* bandpassFilt_1024_cuda(CvMat* rawMat);                 



 virtual    void   zeroFilter_cuda(CvMat* rawMat,Complex*filterOutput);   


	                                                                                
 virtual  void computeDisplacement_cuda(CvMat* inputMat, int  multiWin, int winSize, int stepSize, CvMat*outputMat);


                                                                       
  virtual  void  zeroDisplacement_cuda(CvMat* inputMat, int  multiWin, int winSize, int stepSize, Complex*disOutput);





  virtual	CvMat* lowpassFilt_799_cuda(CvMat* disMat);                 



  virtual  void   strainCalculate_cuda(CvMat*dis,  CvMat* fitMat);     //����Ӧ��ֵ



  virtual  void   random_proess_cuda(CvMat*fitMat, ConfigParam*config, EOutput &output);


  virtual  void    RadonProcess2(CvPoint &s, CvPoint &e, ConfigParam*config,  const CvRect &rect, const CvMat &matStrain);


  virtual  void    RadonSum(const CvMat *pmatDisplacement, CvMat **ppmatRadan);  


  virtual  void  ImagePostProc(IplImage *pImg, const char *filename, const CvPoint &s, const CvPoint &e);




public:                                  



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