function starts = bullshit_hypnostart()
base_home = pwd;
home = 'D:/Glutamate Study';
b = dir('D:/Glutamate Study/AidRLS,*');
starts = cell(size(b,1),2);

cd(home);

for i = 1:size(b,1)
   cd(b(i).name);
   subj = dir('*-results.mat');
   load(subj(1).name, 'plm_outputs');
   subj = subj(1).name; subj = subj(1:end-12);
   starts{i,1} = subj;
   starts{i,2} = plm_outputs.hypnostart;
   
   cd(home)  
end
cd(base_home)