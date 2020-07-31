
function data = matReadmask(filename)
% inp = load(filename);
% f = fields(inp);
% data = inp.(f{1})>0;  

inp = load(filename);
f = fields(inp);
data = inp.(f{1}); 
data = imboxfilt3(data, [5,5,5]);

end