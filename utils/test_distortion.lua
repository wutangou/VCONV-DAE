require 'torch'   -- torch
require 'xlua'    -- xlua provides useful tools, like progress bars
require 'nn'

matio = require 'matio'
model = torch.load('sofa/log_exp_32_128_32_.5_1_diff_arch/'..'model.net')
criterion =  nn.MSECriterion()

trainData = {
	data = {},
	labels = {},
	size = function() return trsize end
	}
testData = {
	data = {},
	labels = {},	
	size = function() return tesize end
	}
model:evaluate()

testData.data = matio.load('Data/dist_sofa_te.mat', 'te_distorted_10')
tesize = testData.data:size()[1]
--trainData.data = matio.load('bed_tr.mat', 'tr_data')
testData.labels = matio.load('sofa_te.mat', 'te_data')

inputs = torch.Tensor(tesize,1,30,30,30) 
outputs = torch.Tensor(tesize,1,30,30,30) 
perfect_cubes = torch.Tensor(tesize,1,30,30,30) 

for k = 1,tesize,1 do
     input = testData.data[k]
     perfect_input = testData.labels[k]
     input = input:double()      
     perfect_input  =  perfect_input:double() 
     perfect_cubes[k] =  perfect_input                		
     inputs[k] = input       
end

outputs = model:forward(inputs)
outputs = torch.reshape(outputs,tesize,1,30,30,30)
--outputs = outputs:floats()
-- now that you have the output, estimate the error on the denoising task by only considering those voxels which were shut down at test time randomly.
err = 0
tot_noisy_voxels = 0

for i = 1,tesize,1 do
	--i = 1150
	noisy_cube = inputs[i]
	perfect_cube = perfect_cubes[i]
	denoised_voxels_tensor = torch.ne(noisy_cube,perfect_cube)  -- this will give me a zero one tensor (1,30,30,30)indicating 1 where the cubes are equal in value and 0 otherwise
	
	denoised_voxels_idx = torch.nonzero(denoised_voxels_tensor) -- this will give x by 4 (2 dims) matrix

	if denoised_voxels_idx:nElement() ~= 0 then
	
		no_noisy_vox = denoised_voxels_idx:size()[1]
	--print(denoised_voxels_idx)

		ee = denoised_voxels_idx
		output = outputs[i]
		bin_output = torch.gt(output, .4 )
		bin_output = bin_output:double()
		perfect_out = perfect_cubes[i]

		wrong_vox= 0
	--noisy_output = output   -- get the output of noisy voxels by proper indexing 
		if   no_noisy_vox ==0  then
			err = err
		else	
		--aa = output:size()
		--print(aa)
			for j = 1,no_noisy_vox,1 do
			
				voxel_label = perfect_out[{{ee[{j,1}]},{ee[{j,2}]}, {ee[{j,3}]}, {ee[{j,4}]}}] -- this should be always one since we only shut down voxels during noising..bug otherwise
				
		 		predicted_output = output[{{ee[{j,1}]},{ee[{j,2}]}, {ee[{j,3}]}, {ee[{j,4}]}}]  -- actual predicted ouput value
				aa = predicted_output[1][1][1][1]
 				predicted_label = bin_output[{{ee[{j,1}]},{ee[{j,2}]}, {ee[{j,3}]}, {ee[{j,4}]}}] -- output of noisy voxel one by one
			--take the diff between noisy and perfect that is all
			--print(predicted_output)
			--print(predicted_label)

				
				bb = aa <.4 
				if bb then
					wrong_vox = wrong_vox + 1
				end
			
		--print('next voxel') 
			end
			err = err + wrong_vox
			tot_noisy_voxels = tot_noisy_voxels +no_noisy_vox
		end

	end --for if else loop

end --for outer for loop on i
print(err)
print(tot_noisy_voxels)
print(err/tot_noisy_voxels)
print('average noisy voxels per example = ' ..err/tesize )
--matio.save('outputs_dist3_tr.mat',outputs)



