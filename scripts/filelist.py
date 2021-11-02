#!/usr/bin/env python3

import sys,os,re
import yaml
from ruamel.yaml import YAML
import collections


topsrc_fl = sys.argv[1]
if len(sys.argv) == 3:
    run_target = sys.argv[2]
else:
    run_target = ''

PROJ_PATH = os.environ['PROJ_PATH']

def dedupe(items):
    seen = [] 
    for item in items:
        if item not in seen:
            yield item
            seen.append(item) 

def read_yml(topsrc_fl, run_target):

    sv_lst   = []
    incd_lst = []
    bb_lst   = []
    define_lst = []
    
    yaml = YAML(typ='safe')
    fl = open(topsrc_fl,'r',encoding='utf-8') 
    topsrc_dict = yaml.load(fl)
    topname = list(topsrc_dict.keys())[0]
    root_path = os.path.dirname(os.path.abspath(topsrc_fl)) +'/'

    if 'define' in topsrc_dict[topname].keys():
        for defines in topsrc_dict[topname]['define']:
            define_lst.append(defines)

    if 'bblist' in topsrc_dict[topname].keys():
        bb_lst.extend(topsrc_dict[topname]['bblist'])

    if 'incdirs' in topsrc_dict[topname].keys():
        for incds in topsrc_dict[topname]['incdirs']:
            abs_path = root_path + incds
            env_path = re.sub(PROJ_PATH,'$PROJ_PATH/',abs_path)
            if os.path.exists(abs_path):
                incd_lst.append('+incdir+'+ env_path)
            else:
                print('***ERROR no such file, please check your yml ====> ',abs_path)
                sys.exit()

    if 'target' in topsrc_dict[topname].keys() and run_target.strip() != '':
        #print("target---->  ",topsrc_dict[topname]['target'].keys())
        #print("topname--->  ",topname)
        if run_target in topsrc_dict[topname]['target'].keys():
            for k in topsrc_dict[topname]['target'][run_target].keys(): 
                if k.endswith('_files'):
                    for fls in topsrc_dict[topname]['target'][run_target][k]:
                        abs_path = root_path + fls
                        env_path = re.sub(PROJ_PATH,'$PROJ_PATH/',abs_path)
                        if os.path.exists(abs_path):
                            sv_lst.append(env_path)
                        else:
                            print('***ERROR no such file, please check your yml ====> ',abs_path)
                            sys.exit()

                elif k.endswith('_filepak'):
                    for fls in topsrc_dict[topname]['target'][run_target][k]:
                        src_fl = root_path + fls
                        module_name = os.path.basename(src_fl).split('.')[0]
                        if os.path.exists(src_fl):
                            if module_name in bb_lst:
                                bb_path = re.sub(module_name+'.yml', 'rtl/'+module_name+'_bb.sv',src_fl)
                                env_bb_path = re.sub(PROJ_PATH,'$PROJ_PATH/',bb_path)
                                sv_lst.append(env_bb_path)
                            else:
                                incd_lst_tmp,sv_lst_tmp,define_lst_tmp = read_yml(src_fl,run_target)
                                sv_lst.extend(sv_lst_tmp)
                                incd_lst.extend(incd_lst_tmp)
                                define_lst.extend(define_lst_tmp)
                        else:
                            print('***ERROR no such file, please check your yml ====> ',src_fl)
                            sys.exit()
        else:
            pass
    
    if 'files' in topsrc_dict[topname].keys():
        for fls in topsrc_dict[topname]['files']:
            abs_path = root_path + fls
            env_path = re.sub(PROJ_PATH,'$PROJ_PATH/',abs_path)
            module_name = os.path.basename(abs_path).split('.')[0]
            if os.path.exists(abs_path):
                if module_name in bb_lst:
                    bb_path = re.sub(module_name, module_name+'_bb',env_path)
                    sv_lst.append(bb_path)
                else: 
                    sv_lst.append(env_path)
            else:
                print('***ERROR no such file, please check your yml ====> ',abs_path)
                sys.exit()

    if 'filepak' in topsrc_dict[topname].keys():
        for item in topsrc_dict[topname]['filepak']:
            src_fl = root_path + item
            print("=====>",src_fl)
            module_name = os.path.basename(src_fl).split('.')[0]
            if os.path.exists(src_fl):
                if module_name in bb_lst:
                    bb_path = re.sub(module_name+'.yml', 'rtl/'+module_name+'_bb.sv',src_fl)
                    env_bb_path = re.sub(PROJ_PATH,'$PROJ_PATH/',bb_path)
                    sv_lst.append(env_bb_path)
                else:
                    incd_lst_tmp,sv_lst_tmp,define_lst_tmp = read_yml(src_fl,run_target)
                    sv_lst.extend(sv_lst_tmp)
                    incd_lst.extend(incd_lst_tmp)
                    define_lst.extend(define_lst_tmp)
            else:
                print('***ERROR no such file, please check your yml ====> ',src_fl)
                sys.exit()
    

    return incd_lst, sv_lst, define_lst 


def print_dc(incd_lst,sv_lst,pkg_lst,filename):
    
    setup_file = open('dc_setup.setup','w')
    for i in dedupe(incd_lst):
        path = re.sub('\$PROJ_PATH/',PROJ_PATH,i)
        line = re.sub('\+incdir\+',"set search_path \"$search_path ",path)+"\""
        setup_file.write(line + '\n')
    setup_file.close()

    fl_list = open('filelist.tcl','w')
    fl_list.write('set rtl_list { \\'+ '\n')
    for j in dedupe(pkg_lst + sv_lst):
        path = re.sub('\$PROJ_PATH/',PROJ_PATH,j)
        fl_list.write(path +' \\' +'\n')
    fl_list.write('}'+ '\n')
    fl_list.close()


pkg_lst = []
incd_lst, sv_lst, define_lst = read_yml(topsrc_fl,run_target)
for k in sv_lst:
    if re.search('pkg',k):
        pkg_lst.append(k)
        sv_lst.remove(k)

filename = os.path.basename(topsrc_fl).split('.')[0] 
dest_fl = open(filename+'.f','w')
for i in dedupe(define_lst + incd_lst + pkg_lst + sv_lst):
    dest_fl.write(i + '\n')
dest_fl.close()
print('===Generate filelist successfully!===>> ')

print_dc(incd_lst,sv_lst,pkg_lst,filename)
print('===Generate dc_filelist successfully!===>> ')

   







#class all_date:
#    def top_src(self,modulenamelst,target):
#        self.module = modulenamelst
#        self.tgt = target
#        return self.module, self.tgt
#
#    def module_src(self,includes,files):
#        self.incd = includes
#        self.fl = files

