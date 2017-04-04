--- this script is divided in two parts based on an if-else statement 
-- first part (encoder ==1) takes a  trained model and a class model as input and saves the enocder part in a binary file  
-- second part (encoder=0, decoder =1) takes input a mat file of 

require 'cunn'
require 'nn'
matio = require 'matio'

---
encoder= 1;
class = 'bed'
model_no = '0051_1'
save_en_dir = ('/BS/deep_3d/work/deep_3d/fcn_3D/view-interp/'..class..'/encoded_desc/'..class..'_'..model_no..'.asc')

--parameters for decoder
mat_str = ('/BS/deep_3d/work/deep_3d/fcn_3D/Data-Mat-40/'..class..'/30/train/'..class..'_'..model_no..'.mat')	
print(mat_str)	
interp_str = ('/BS/deep_3d/work/deep_3d/fcn_3D/view-interp/'..class..'/encoded_desc/interpolated_desc.mat')


model = torch.load('mul-class-models/AE_6912_.1_10class_r/'..'model.net') --this loads the network
print(model)
desc_dims = 6912 

--model = model:double()

input = {data = {}}

if encoder==1 then
	print('removing the decoder part')
	
	model:remove(15)  --remove sigmoid as well
	model:remove(14)
	model:remove(13)
	model:remove(12)
	model:remove(11)	
	model:remove(10)		
	model:evaluate()

	 --for i =1,2 do 	
		inputs = torch.Tensor(1,1,30,30,30) 
		inputs = inputs:cuda()
		input = matio.load(mat_str, 'instance');
		input = input:cuda()
		inputs[1] = input
		outputs = model:forward(inputs)
		outputs = outputs:float()
	--end
	--outputs = torch.reshape(outputs,30,30,30)
	--outputs = torch.squeeze(outputs)
	--dims = outputs:nDimension()
	--if dims > 1  then
    		--for i=1,math.floor(dims/2) do
      		--outputs=outputs:transpose(i, dims-i+1)
    	--end

    	--outputs = outputs:contiguous()

-- saving the descriptor (encoder) of an object instance
	file = torch.DiskFile(save_en_dir, 'w')
	file:writeObject(outputs)
	file:close()

else
	print('decoding the interpolated encoder')
	model:remove(9)
	model:remove(8)
	model:remove(7)
	model:remove(6)
	model:remove(5)  
	model:remove(4)
	model:remove(3)
	model:remove(2)
	model:remove(1)
	model:evaluate()
	print(model)

	interp_desc = matio.load(interp_str , 'interp_desc') -- this is 2 by 6912


	--interp_desc = matio.load('/BS/deep_3d/work/deep_3d/fcn_3D/view-interp/chair/encoded_desc/chair_25_3.mat', 'desc_6912')		
	total_desc = interp_desc:size()[1]

	for i = 1,total_desc do 
		--inputs = torch.Tensor(1,6912)
		--inputs = inputs:cuda()
		--input = interp_desc:select(2,i) -- select second column
		input = interp_desc[i]
		--input = interp_desc
		print(input:size())
		input = input:cuda()
		inputs = input
		outputs = model:forward(input)	
	
-- fwd the interpolaed ones to the network and save the output
		outputs = torch.reshape(outputs,30,30,30)
		outputs = torch.squeeze(outputs)
		dims = outputs:nDimension()

		if dims > 1  then
    			for i=1,math.floor(dims/2) do
      			outputs=outputs:transpose(i,dims-i+1)
    			end
    			outputs = outputs:contiguous()
		end	

		idx  = torch.range(1,total_desc)

		save_str = ('/BS/deep_3d/work/deep_3d/fcn_3D/view-interp/'..class..'/interp_desc/'..class..'_int_'..idx[i]..'.asc')
		print(save_str)
	--file = torch.DiskFile('/BS/deep_3d/work/deep_3d/fcn_3D/view-interp/chair/interp_desc/chair_int_2.asc', 'w')
		file = torch.DiskFile(save_str, 'w')
		file:writeObject(outputs)
		file:close()
	end

end

