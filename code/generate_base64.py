# import base64
# # 二进制方式打开图文件
# f = open('/Users/jason/code/leisure/doc/docker/foundations/workflow/imgs/airflow_1.png', 'rb')
# ls_f = base64.b64encode(f.read())  # 读取文件内容，转换为base64编码
# f.close()
# print(ls_f)

import os
import base64


class GenerateBase64(object):
    def __init__(self, target_dir):
        self.target_dir = os.path.dirname(
            os.path.dirname(os.path.abspath(__file__))) + target_dir

    def get_file_path(self):
        filenames = []  # 当前路径下所有非目录子文件
        for dirpath, dirs, filename in os.walk(self.target_dir):
            for file in filename:
                filenames.append(dirpath + "/" + file)
        filenames.sort()
        print(filenames)
        return filenames

    def generate_base64(self):
        filebase64 = []
        filenames = self.get_file_path()
        for filename in filenames:
            files = open(filename, 'rb')
            file_byte = base64.b64encode(files.read())  # 读取文件内容，转换为base64编码
            filebase64.append('[' + filename[filename.rfind('/')+1: filename.find('.')
                                 ] + ']:data:image/png;base64,' + file_byte.decode('utf8'))
        files.close()

        
    def print_base64(self):
        mytxt = open('out.txt', mode='a', encoding='utf-8')
        for i in self.filebase64:
           print(i, file=mytxt)
        mytxt.close()

if __name__ == "__main__":
    gen = GenerateBase64("/foundations/workflow/imgs")
    gen.generate_base64()
