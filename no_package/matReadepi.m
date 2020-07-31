function data = matReadepi(filename)
inp = load(filename);
f = fields(inp);
data = inp.(f{1});  
data(isnan(data))=0;
end