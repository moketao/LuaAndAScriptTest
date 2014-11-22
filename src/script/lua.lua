local main=nil

function setMain(_main)
	main = _main
end

function internalEmptyCall(count)
	count=100000
	for i=1,count do 
		emptyFunction()
	end
end

function emptyFunction()
end

function emptyCallFromScriptToAs3(count)
	count=100000
	for i=1,count do 
		main:emptyFunction()
	end
end

function cumsum(count)
	count=100000
	local sum=0
	for i=1,count do 
		sum=sum+i
	end
end
