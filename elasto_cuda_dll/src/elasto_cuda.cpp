
#include "stdafx.h"

#define ELASTO__EXPORTS   

#include "elasto_cuda.h"

#include "stdio.h"

#include  "lib_add_cuda.cuh"

#include  "CElasto.h"  

#include  "SysConfig.h"

#include "CData.h"

#include  "cuda_main.cuh"





ElastoCuda::ElastoCuda()  {

	initFile   = defaultElastoConfFile;

	  config   = new  ConfigParam;

	cudaMain   = new  CudaMain();

}





ElastoCuda::~ElastoCuda()  {

	delete    initFile;

	delete    cudaMain;

}



bool  ElastoCuda::isAvailable()  {

	return    cudaMain->isAvailable();

}



void  ElastoCuda::init(const EInput & in) {


	initFile = defaultElastoConfFile;


	ReadSysConfig( initFile,  *config);                                            // ��ȡ�ļ���ȡ����


//	readRFData(in);                                                                //  ��ȡrf����

	

//	cudaMain->inputRfData( in);                                                    //  ��ȡRF����,��cpu_inputMat 

	cudaMain->inputConfigParam(config);                                            //  ���ò��� ��cpu_config


	cudaMain->getlowFilterParam( config->lpfilt_file);                            // ��ȡ�˲�����ͨ��������


	cudaMain->getbandFilterParam(config->bpfilt_file);                           // ��ȡ�˲�����ͨ��������


	cudaMain->getmatchFilterParam(config->matchfilt_file);                        // ��ȡ�˲���ƥ���������

	

	cudaMain->mallocMem();                                                         //  �����ڴ�


	cudaMain->inputRfData(in);                                                    //  ��ȡRF����,��cpu_inputMat 


}


void   ElastoCuda::readRFData(const EInput & in)   {

	std::string filename;

	filename = in.filepath_s;

	CData*test = new CData(in.rows, in.cols);
	
	test->readData(in.pDatas);


}










bool  ElastoCuda::process(const EInput &input, EOutput &output)  {

	init(input);
	   
	cudaMain->process(input, output);



	return  true;


}

















