import casadi.*

n = 5;
x = MX.sym('x',n,n);
y = MX.sym('y',Sparsity.lower(n));

w = x*3;

w = w*y;

w = sin(w);
w = w./DM(magic(n));

w(1:2) = y(1);

g = {w, norm(w,'fro')};

Xc = {x,y};
for i=1:2
  X = Xc{i};

  M = [vec([X;X])];
  M2 = [X(3,:);X(2,:);X(1:3,:)]+3;
  M3 = vertsplit(X,2);
  M4 = vertsplit(vec(X),2);
  M5 = diagcat(X,2*X);
  g = {g{:} M, M2, M3{1}, M4{1},M5,M5+3,2*X};
end
g = {g{:}, 1./x};


args = symvar(veccat(g{:}));
f_mx = Function('f',args,g);
f_sx = f_mx.expand();

f_mx.export_code('matlab','f_mx_exported.m')
f_sx.export_code('matlab','f_sx_exported.m')
rehash

rng(1);

N = f_mx.n_out;

args_num = {};
for i=1:f_mx.n_in
   a = args{i};
   args_num{i} = sparse(casadi.DM(sparsity(a),rand(nnz(a),1)));
end

f_mx_res = cell(1,1);
f_sx_res = cell(1,1);
f_mx_exported_res = cell(1,1);
f_sx_exported_res = cell(1,1);

[f_mx_res{1:N}] = f_mx(args_num{:});
[f_sx_res{1:N}]  = f_sx(args_num{:});

[f_mx_exported_res{1:N}] = f_mx_exported(args_num{:});
[f_sx_exported_res{1:N}] = f_sx_exported(args_num{:});

for i=1:length(f_mx_res)
    assert(norm(full(f_mx_res{i}-f_sx_res{i}))<1e-12);
    assert(norm(full(f_mx_res{i}-f_mx_exported_res{i}))<1e-12);
    assert(norm(full(f_mx_res{i}-f_sx_exported_res{i}))<1e-12);
end

delete('f_mx_exported.m')
delete('f_sx_exported.m')