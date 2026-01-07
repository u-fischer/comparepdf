--loop over all lvt: $ for f in ./*.lvt; do comparepdf.bat -r1 -p -elvt ${f%.*} 2>>comparepdf.log; done

local engine='lualatex-dev'
local filename = 'test-utf8'
local compilelegacy = true
local compilenew = true
local errorlevel
local runs=2
local ext="tex"
local resetencoding =''
local density = 300
local view=false

-- current options (rather crude needs reviewing ...)
-- -p: use pdflatex-dev
-- -l: do not compile legacy PDF
-- -n: do not compile new PDF
-- -v: run viewer
-- -rN: set runs to N
-- -eXXX: set file extension to .XXX
-- -dNNN: set density to NNN (higher density is slower!)
-- other: file name

for i = 1,#arg do
  if arg[i] then
   if arg[i]=='-p' then
     engine = 'pdflatex-dev'
     resetencoding = '\\def\\encodingdefault{T1}'
   elseif arg[i]=='-l' then
     compilelegacy = false
   elseif arg[i]=='-n' then
     compilenew = false 
   elseif string.find(arg[i], "^-r") then
     _,_, runs = string.find(arg[i], "^-r(%d+)")
     print("runs",runs)
   elseif string.find(arg[i], "^-e") then
     _,_, ext = string.find(arg[i], "^-e(%a+)")      
   elseif string.find(arg[i], "^-d") then
     _,_, density = string.find(arg[i], "^-d(%d+)")       
   elseif string.find(arg[i], "^-v") then
     view = true
   else 
    filename = arg[i]
   end    
  end
end

-- legacy compilation should at least set the page geometry and use T1 too

function legacysettings()
 local legacy = '\\def\\DocumentMetadata#1{}'
 legacy = legacy .. '\\RequirePackage{pdfmanagement,amsmath}'
 legacy = legacy .. '\\AddToHook{begindocument/before}{\\usepackage{array}}'
 legacy = legacy .. '\\def\\DebugFNotesOn{}'
 legacy = legacy .. '\\def\\DebugMathOn{}'
 legacy = legacy .. '\\def\\DebugBlocksOn{}'
 legacy = legacy .. '\\def\\DebugBlocksOff{}'
 legacy = legacy .. '\\def\\ShowTagging#1{}'
 legacy = legacy .. '\\ExpandArgs{c}\\def{math_processor:n}#1{}'
 legacy = legacy .. resetencoding 
 return legacy
end

local shellquote="'"
local startprog="xdg-open"
if os.type=="windows" then
  shellquote=""
  startprog="start"
end

local setting =shellquote .. legacysettings().." \\input" .. shellquote

local legacycompilation = engine ..' --jobname='..filename..'-legacy '..setting..'{'.. filename..'.'..ext..'}'   
local newcompilation = engine ..' --jobname='..filename..'-new '.. filename ..'.'..ext

f = io.open(filename.."."..ext)
if not f then
 io.stderr:write("\nfile "..filename.."."..ext.." doesn't exist -- quitting")
return 1
else 
f:close()
end

-- compile legacy pdf
if compilelegacy then
 for i=1,runs do
   errorlevel=os.execute(legacycompilation)
   if errorlevel ~= 0 then
    io.stderr:write("\ncompilation of "..filename.."-legacy.pdf didn't succeed -- quitting")
    return 1
   end 
 end
end

-- check it exists
f = io.open(filename.."-legacy.pdf") 
if not f then
 io.stderr:write("\n"..filename.."-legacy.pdf missing -- quitting")
 return 1
else
f:close()
end

-- compile new pdf
if compilenew then
 for i=1,runs do
 errorlevel=os.execute(newcompilation)
   if errorlevel ~= 0 then
    io.stderr:write("\ncompilation of "..filename.."-new.pdf didn't succeed -- quitting")
    return 1
   end 
 end
end 

 
-- check it exists 
f = io.open(filename.."-new.pdf")
if not f then 
 io.stderr:write("\n"..filename.."-new.pdf missing -- quitting")
 return 1
else 
f:close()
end

-- get page numbers
local handle = io.popen("qpdf --show-npages "..filename.."-legacy.pdf")
local legacypages = handle:read("*number")
handle:close()
local handle = io.popen("qpdf --show-npages "..filename.."-new.pdf")
local newpages = handle:read("*number")
handle:close()

print("Checking "..math.min(legacypages,newpages).." page(s)!")

function magickcall(filename,density,page) 
 local pagenum=page+1
 local call =  'magick compare -highlight-color blue -density ' .. density ..' '
 call = call .. filename..'-legacy.pdf['..page..'] '
 call = call .. filename..'-new.pdf['..page..'] '
 call = call .. filename..'-diff-'..pagenum..'.png '
 call = call .. '2>&1' 
 return call
end

for page=1,math.min(legacypages,newpages) do
 local handle = io.popen (magickcall(filename,density,page-1)) 
 local report = handle:read("*a") 
 local nodiff = handle:close()
 if nodiff then
   io.stdout:write ('\n'..filename..'.'..ext..': No differences on page '..page..'.')  
   os.remove(filename..'-diff-'..page..'.png')  
 else
   io.stderr:write ('\n'..filename..'.'..ext..': Difference on page '.. page..' with values '..report..'.')
   if view then
    os.execute(startprog .. ' '..filename..'-diff-'..page..'.png')
   end 
 end 
end 
