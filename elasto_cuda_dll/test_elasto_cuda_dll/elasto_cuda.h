
#ifndef   _ELASTO_CUDA

#define   _ELASTO_CUDA

#ifdef      ELASTO__EXPORTS

#define     ELASTO_API __declspec(dllexport) //�������ź궨��


#else

#define     ELASTO_API __declspec(dllimport) //�������ź궨��

#endif

#include  <string>


 // #include  "lib_add_cuda.cuh"

 #include  "CElasto.h"  

//#include  "SysConfig.h"


//struct  EInput    ;

//struct  EOutput   ;

struct ConfigParam;

class   CudaMain ;


  char defaultElastoConfFile[] = ".\\config.ini";


  ConfigParam  paramConfig;



     class     __declspec(dllexport)      ElastoCuda    {

	
private :

	 char *        initFile;

	CudaMain  *    cudaMain;

	ConfigParam *  config;



private:                         //��ȡԭʼRF���� ����ȡ�˲������ݣ���ȡ��������


	void   readRFData(const EInput & in);








public:

	ElastoCuda();



	~ElastoCuda(); 

	virtual bool  isAvailable();

	virtual int   ci() const { return 40; };

	virtual void  init(const EInput & input);

	virtual bool  process( const EInput &input, EOutput &output);










};




#undef ELASTO_API







#endif