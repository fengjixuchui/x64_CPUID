
extrn ExitProcess: PROC
extrn lstrlenA: PROC
extrn WriteConsoleA: PROC
extrn SetConsoleTextAttribute: PROC
extrn SetConsoleMode: PROC
extrn GetConsoleMode: PROC
extrn ReadConsoleA: PROC 
extrn GetStdHandle: PROC
extrn wsprintfA: PROC
extrn SetConsoleScreenBufferSize: PROC
extrn GetConsoleScreenBufferInfo: PROC
extrn SetConsoleTitleA: PROC
extrn WriteConsoleOutputCharacterA: PROC
extrn WriteConsoleOutputAttribute: PROC


ENABLE_LINE_INPUT		equ 0002h

FOREGROUND_RED			equ 0004h
FOREGROUND_GREEN		equ 0002h
FOREGROUND_BLUE			equ 0001h

COLOR1					equ FOREGROUND_GREEN or FOREGROUND_RED or FOREGROUND_BLUE
COLOR2					equ FOREGROUND_GREEN or FOREGROUND_RED
COLOR3					equ FOREGROUND_BLUE or FOREGROUND_RED
COLOR4					equ FOREGROUND_BLUE or FOREGROUND_GREEN
COLOR5					equ FOREGROUND_BLUE
COLOR6					equ FOREGROUND_RED
COLOR7					equ FOREGROUND_GREEN
COLOR8					equ 0Fh

STD_OUTPUT_HANDLE		equ -11
STD_INPUT_HANDLE		equ -10



COORD STRUCT
    X WORD ?
    Y WORD ?
COORD ENDS

SMALL_RECT STRUCT
  Left     WORD ?  
  Top      WORD ?  
  Right    WORD ?  
  Bottom   WORD ?  
SMALL_RECT ENDS

CONSOLE_SCREEN_BUFFER_INFO STRUCT
  dwSize        COORD <>
  dwCursorPos   COORD <>
  wAttributes   WORD ?
  srWindow      SMALL_RECT <>
  dwMaxWinSize  COORD <>
CONSOLE_SCREEN_BUFFER_INFO ENDS


ArrayNextElement MACRO ElementLen, Value
	db Value, 0
	db ElementLen-@SizeStr(Value)+1 dup(?)
ENDM

ArrayNextFourElements MACRO ElementLen, Value1, Value2, Value3, Value4
	ArrayNextElement ElementLen, Value1
	ArrayNextElement ElementLen, Value2
	ArrayNextElement ElementLen, Value3
	ArrayNextElement ElementLen, Value4
ENDM

.data
	hStdOutput				dq ? 
	hStdInput				dq ? 

	defSystemAttrib			dw ?	
	defProgramAttrib		dw 0Fh	

	str_AnyKeyToExit		db 0ah, '  Press any key to exit...', 0
	str_NewLine				db 0ah, 0
	
	str_title				db '[cpuid]', 0

	table1_colors			db COLOR4, COLOR8
	table2_colors			db COLOR1, COLOR7

	
	bit_label_ecx:
	ArrayNextFourElements 48, 'Reserved', 'RDRAND', 'F16C', 'AVX'
	ArrayNextFourElements 48, 'OSXSAVE', 'XSAVE', 'AES', 'TSC-Deadline'
	ArrayNextFourElements 48, 'POPCNT', 'MOVBE', 'x2APIC', 'SSE4.2'
	ArrayNextFourElements 48, 'SSE4.1', 'DCA - Direct Cache Access', 'PCID - Process-context Identifiers', 'Reserved'
	ArrayNextFourElements 48, 'PDCM - Perf/Debug Capability MSR', 'xTPR Update Control', 'CMPXCHG16B','FMA - Fused Multiply Add'
	ArrayNextFourElements 48, 'Reserved', 'CNXT-ID - L1 Context ID', 'SSSE3 Extensions', 'TM2 Thermal Monitor 2'
	ArrayNextFourElements 48, 'EST - Enhansed Intel SpeedStep(R) Technology','SMX - Safer Mode Extensions', 'VMX - Virtual Machine Extensions', 'DS-CPL - CPL Qualified Extensions'
	ArrayNextFourElements 48, 'MONITOR - MONITOR/MWAIT','DTES64 - 64-bit DS Area','PCLMULQDQ - Carryles Multiplication', 'SSE3 Extensions'

	
	bit_label_edx:
	ArrayNextFourElements 48, 'PBE - Rend. Brk. EN.','Reserved','TM-Therm. Monitor','HTT - Multi-threading'
	ArrayNextFourElements 48, 'SS - Self Snoop','SSE2 Extensions','SSE Extensions','FXSR - FXSAVE/FXRSTOR'
	ArrayNextFourElements 48, 'MMX Technology','ACPI - TM and Clock Ctrl','DS - Debug Store','Reserved'
	ArrayNextFourElements 48, 'CLFSH - CFLUSH Instruction','PSN - Processor Serial Number','PSE-36 - Page Size Extension','PAT - Page Attrbute Table'
	ArrayNextFourElements 48, 'CMOV - Cond. Move/Compare Instr.','MCA - Machine Check Architecture','PGE - PTE Global Bit','MTRR - Memory Type Range Registers'
	ArrayNextFourElements 48, 'SEP - SYSENTER and SYSEXIT','Reserved','APIC on Chip','CX8 - CMPXCHG8B Instruction'
	ArrayNextFourElements 48, 'MCE Machine Check Exception','PAE - Physical Address Extensions','MSR - RDMSR and WRMSR Support','TSC - Time Stamp Counter'
	ArrayNextFourElements 48, 'PSE - Page Size Extensions','DE - Debugging Extensions','VME - Virtual 8086 Mode Enhancement','FPU - x87 FPU on Chip'


	str_eax_feature1		db 'Reserved', 0
	str_eax_feature2		db 'Extended Family ID', 0
	str_eax_feature3		db 'Extended Model ID', 0
	str_eax_feature4		db 'Reserved', 0
	str_eax_feature5		db 'Processor Type', 0
	str_eax_feature6		db 'Family ID', 0
	str_eax_feature7		db 'Model', 0
	str_eax_feature8		db 'Stepping ID', 0

	str_ebx_feature1		db 'Initial APIC Value', 0
	str_ebx_feature2		db 'Logical Processors', 0
	str_ebx_feature3		db 'CLFLUSH Line Size', 0
	str_ebx_feature4		db 'Brand Index', 0

	str_cpuid0				db '  CPUID(0):', 0Ah, 0Ah, 0
	str_MaxCpuidNum			db '   Max cpuid number = ', 0
	str_VendorString		db '   VendorString = ', 0
	str_i					db '%i', 0
	str_s					db '%s', 0
	str_cpuid1				db '  CPUID(1):', 0Ah, 0Ah, 0
	str_nn					db 0Ah, 0Ah, 0

	str_horizontal_line		db 0C4h, 0
	str_corner				db 0D9h, 0
	str_vertical_line		db 0B3h, 0
	str_space				db ' ', 0

.code




	
	
	
	PrintString PROC USES rax rcx rdx r8 r9 r10 r11 r15 pStr:QWORD
	LOCAL bytesWritten:QWORD
		mov r15, rsp				
		and spl, 0f0h				
		sub rsp, 8*4				
		sub rsp, 8*2				
									
		mov rcx, pStr				
		call lstrlenA				
									
		mov qword ptr [rsp+20h], 0	
		lea r9, bytesWritten		
		mov r8, rax					
		mov rdx, pStr				
		mov rcx, hStdOutput			
		call WriteConsoleA
		mov rsp, r15				
		ret 8*1
	PrintString ENDP

	
	
	
	
	PrintStringAttr PROC USES rax rcx rdx rsi r8 r9 r10 r11 r15 pStr:QWORD, Attr:WORD
		mov r15, rsp					
		and spl, 0f0h					
		sub rsp, 8*4					
		sub rsp, 8*0					
										
		mov rsi, SetConsoleTextAttribute	
		mov dx, Attr					
		mov rcx, hStdOutput				
		call rsi						
		push pStr
		call PrintString				
		mov dx, defProgramAttrib		
		mov rcx, hStdOutput				
		call rsi						
		mov rsp, r15					
		ret 8*2	
	PrintStringAttr ENDP

	
	WaitAndTerminate PROC
	LOCAL bytesReaded:QWORD
	LOCAL lpMode:QWORD
	LOCAL char:BYTE
		and spl, 0f0h					
		sub rsp, 8*4					
		sub rsp, 8*2					
										
		lea rax, str_AnyKeyToExit
		push rax
		call PrintString				
		lea rdx, lpMode					
		mov rcx, hStdInput				
		call GetConsoleMode				
		mov rdx, lpMode					
		and rdx, not ENABLE_LINE_INPUT	
		mov rcx, hStdInput				
		call SetConsoleMode				
		mov qword ptr [rsp+20h], 0		
		lea r9, bytesReaded				
		mov r8, 1						
		lea rdx, char					
		mov rcx, hStdInput				
		call ReadConsoleA				
		lea rax, str_NewLine
		push rax
		call PrintString				
		mov rdx, lpMode					
		mov rcx, hStdInput				
		call SetConsoleMode				
		mov dx, defSystemAttrib			
		mov rcx, hStdOutput				
		call SetConsoleTextAttribute	
		mov rcx, 0						
		call ExitProcess				
		int 3							
	WaitAndTerminate ENDP


	
	
	
	
	
	
	
	PrintCoolTable PROC USES rax rbx rcx rdx rsi r8 r9 r10 r11 r15 bits_str:QWORD, space_divder:QWORD, bit_names:QWORD, space_before:QWORD, colors:QWORD, colorcount:BYTE
	LOCAL bit[2]: BYTE
		mov r15, rsp					
		and spl, 0f0h					
		sub rsp, 8*4					

		xor rax, rax					
		mov rcx, space_before			
space_before_next:						;
		cmp rax, rcx					;
		jae space_before_final
		lea rdx, str_space
		push rdx
		call PrintString
		inc rax
		jmp space_before_next
space_before_final:

		xor rax, rax					
		mov rcx, space_divder			
space_divder_next:
		cmp rax, rcx
		jae space_divder_final
		lea rdx, str_space
		push rdx
		call PrintString
		inc rax
		jmp space_divder_next
space_divder_final:

		xor rax, rax					
		mov rcx, 32						
		mov bit[1], 0
print_bits_next:
		cmp rax, rcx
		jae print_bits_final
		mov rbx, bits_str
		mov dl, byte ptr [rbx+rax]
		mov bit[0], dl

		xor rbx, rbx					
		xor rdx, rdx
		mov bl, colorcount
		push rax
		div bx
		
		
		pop rax

		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		lea rdx, bit
		push rdx
		call PrintStringAttr

		inc rax
		jmp print_bits_next
print_bits_final:


		lea rdx, str_NewLine			
		push rdx
		call PrintString


		xor rax, rax					
		mov rcx, space_before
space_before_next1:
		cmp rax, rcx
		jae space_before_final1
		lea rdx, str_space
		push rdx
		call PrintString
		inc rax
		jmp space_before_next1
space_before_final1:

		xor rax, rax					
		mov rcx, space_divder
space_divder_next1:
		cmp rax, rcx
		jae space_divder_final1
		lea rdx, str_space
		push rdx
		call PrintString
		inc rax
		jmp space_divder_next1
space_divder_final1:

		xor rax, rax					
		mov rcx, 32						
print_bits_next1:
		cmp rax, rcx
		jae print_bits_final1

		xor rbx, rbx
		xor rdx, rdx
		mov bl, colorcount
		push rax
		div bx
		
		
		pop rax

		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		lea rdx, str_vertical_line		
		push rdx
		call PrintStringAttr

		inc rax
		jmp print_bits_next1
print_bits_final1:		

		lea rdx, str_NewLine			
		push rdx
		call PrintString

		xor esi, esi					
next_lable:
		cmp esi, 32
		jae lable_final

		xor rax, rax					
		mov rcx, space_before
space_before_next2:
		cmp rax, rcx
		jae space_before_final2
		lea rdx, str_space
		push rdx
		call PrintString
		inc rax
		jmp space_before_next2
space_before_final2:

		xor rdx, rdx					
		xor rbx, rbx
		mov bl, colorcount
		mov ax, si
		div bx
		
		

		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		mov rax, 48
		mul si
		mov rdx, bit_names
		add rdx, rax
		push rdx
		call PrintStringAttr

		mov rcx, rdx					
		call lstrlenA					
		mov rdx, space_divder
		sub rdx, rax
		add rdx, rsi

		xor rax, rax
		mov rcx, rdx
next_sym:
		cmp rax, rcx
		jae sym_end

		xor rdx, rdx					
		xor rbx, rbx
		mov bl, colorcount
		push rax
		mov ax, si
		div bx
		
		
		pop rax
		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		lea rdx, str_horizontal_line
		push rdx
		call PrintStringAttr
		inc rax
		jmp next_sym
sym_end:

		xor rdx, rdx					
		xor rbx, rbx
		mov bl, colorcount
		mov ax, si
		div bx
		
		
		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		lea rdx, str_corner
		push rdx
		call PrintStringAttr

		xor rax, rax					
		mov rcx, 32
		sub rcx, rsi
		dec rcx
next_vert:
		cmp rax, rcx
		jae end_vert

		xor rdx, rdx
		mov rbx, rsi
		add rbx, rax
		inc rbx
		push rax
		mov rax, rbx
		xor rbx, rbx
		mov bl, colorcount
		div bx
		
		
		pop rax
		mov rbx, colors
		movzx rdx, byte ptr [rbx+rdx]
		push rdx
		lea rdx, str_vertical_line
		push rdx
		call PrintStringAttr
		inc rax
		jmp next_vert
end_vert:

		lea rdx, str_NewLine			
		push rdx
		call PrintString

		inc esi
		jmp next_lable					
lable_final:
		mov rsp, r15					
		ret 8*6
	PrintCoolTable ENDP

	
	
	
	
	
	
	PrintBitLabel PROC USES rax rcx rdx rsi r8 r9 r10 r13 r12 bits_str:QWORD, _label:QWORD, hight:QWORD, Attr:WORD, _coord:COORD
	LOCAL numberOfWritten	:DWORD
	LOCAL AttrArr[256]		:WORD
	LOCAL def_x				:WORD
		mov r15, rsp					
		and spl, 0f0h					
		sub rsp, 8*4					
		sub rsp, 8*2					
										
		xor rax, rax
next_attr:								
		cmp rax, 256
		jae attr_end
		mov cx, Attr
		mov AttrArr[rax*2], cx
		inc rax
		jmp next_attr
attr_end:

		mov ax, _coord.X				
		mov def_x, ax

		mov rcx, bits_str			
		call lstrlenA
		mov r13, rax					

		mov rcx, _label
		call lstrlenA
		mov r12, rax					

		sub rax, r13					
		shr rax, 1						

		add _coord.X, ax				

		mov rcx, hStdOutput				
		mov rdx, bits_str
		mov r8, r13
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputCharacterA	

		mov rcx, hStdOutput
		lea rdx, AttrArr
		mov r8, r13
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputAttribute	

		inc _coord.Y

		xor rsi, rsi

cmp_hight:									
		cmp rsi, hight
		jae fin_hight
	
		mov rax, r12						
		sub rax, r13
		shr rax, 1							

		mov cx, def_x
		add cx, ax
		mov _coord.X, cx					

		xor rdi, rdi						
cmp_color_line:
		cmp rdi, r13
		jae end_color_line

		mov rcx, hStdOutput
		lea rdx, str_space
		mov r8, 1
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputCharacterA	

		mov ax, Attr
		shl ax, 4
		mov word ptr [rsp+28h], ax
	
		mov rcx, hStdOutput
		lea rdx, [rsp+28h]
		mov r8, 1
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputAttribute	

		inc _coord.X

		inc rdi
		jmp cmp_color_line
end_color_line:

		inc _coord.Y

		inc rsi
		jmp cmp_hight
fin_hight:

		mov ax, def_x								
		mov _coord.X, ax
	
		mov rcx, hStdOutput
		mov rdx, _label
		mov r8, r12
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputCharacterA			

		mov rcx, hStdOutput
		lea rdx, AttrArr
		mov r8, r12
		mov r9d, _coord
		lea rax, numberOfWritten
		mov qword ptr [rsp+20h], rax						
		call WriteConsoleOutputAttribute	

		inc _coord.Y

		mov rsp, r15					
		ret 8*5
	PrintBitLabel ENDP

	
	
	
	
	NumToBin PROC USES rcx rdx number:DWORD, bits:BYTE, pOutStr:QWORD
		mov rax, pOutStr
		xor rcx, rcx
		mov edx, number
		mov cl, bits
		mov byte ptr[rax+rcx], 0
next_bit:
		test cl, cl
		je final
		push rdx	
		and dl, 1
		add dl, '0'
		dec cl
		mov byte ptr[rax+rcx], dl
		pop rdx
		shr edx, 1
		jmp next_bit
final:
		ret 8*3
	NumToBin ENDP

	Start PROC
	LOCAL _coord					:COORD
	LOCAL csbiInfo					:CONSOLE_SCREEN_BUFFER_INFO
	LOCAL outputData[256]			:BYTE 
	LOCAL cpuid_01[4]				:DWORD 
	LOCAL cpuVendorString[4*3+1]	:BYTE 
		and spl, 0f0h									
		sub rsp, 8*4									
		sub rsp, 8*0									
														
		mov rcx, STD_OUTPUT_HANDLE						
		call GetStdHandle								
		mov hStdOutput, rax
		mov rcx, STD_INPUT_HANDLE						
		call GetStdHandle								
		mov hStdInput, rax		
		mov _coord.x, 80								
		mov _coord.y, 1000								
		xor rdx, rdx
		mov edx, _coord									
		mov rcx, hStdOutput								
		call SetConsoleScreenBufferSize					
		lea rdx, csbiInfo								
		mov rcx, hStdOutput								
		call GetConsoleScreenBufferInfo					
		mov ax, csbiInfo.wAttributes;
		mov defSystemAttrib, ax
		lea rcx, str_title								
		call SetConsoleTitleA							
		xor rdx, rdx
		mov dx, defProgramAttrib						
		mov rcx, hStdOutput								
		call SetConsoleTextAttribute					

		lea rax, str_NewLine
		push rax
		call PrintString
														
		xor rax, rax									
		cpuid
		mov cpuid_01[0*4], eax							
		mov cpuid_01[1*4], ebx
		mov cpuid_01[2*4], ecx
		mov cpuid_01[3*4], edx

		mov dword ptr cpuVendorString+0, ebx			
		mov dword ptr cpuVendorString+4, edx
		mov dword ptr cpuVendorString+8, ecx
		mov byte ptr cpuVendorString+12, 0

		push FOREGROUND_BLUE or FOREGROUND_GREEN
		lea rax, str_cpuid0
		push rax
		call PrintStringAttr

		lea rax, str_MaxCpuidNum
		push rax
		call PrintString

		lea rcx, outputData
		lea rdx, str_i
		xor r8, r8
		mov r8d, cpuid_01[0*4]
		call wsprintfA									

		push FOREGROUND_GREEN
		lea rax, outputData
		push rax
		call PrintStringAttr

		lea rax, str_NewLine
		push rax
		call PrintString
			
		lea rax, str_VendorString
		push rax
		call PrintString

		push FOREGROUND_GREEN
		lea rax, cpuVendorString
		push rax
		call PrintStringAttr

		lea rax, str_nn
		push rax
		call PrintString

		cmp cpuid_01[0*4], 1							
		jb exit

		xor rax, rax
		inc rax
		cpuid
		mov cpuid_01[0*4], eax
		mov cpuid_01[1*4], ebx
		mov cpuid_01[2*4], ecx
		mov cpuid_01[3*4], edx

		push FOREGROUND_BLUE or FOREGROUND_GREEN
		lea rax, str_cpuid1
		push rax
		call PrintStringAttr

		lea rdx, csbiInfo								
		mov rcx, hStdOutput								
		call GetConsoleScreenBufferInfo					

		lea rax, str_NewLine							
		push rax										
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString

		add csbiInfo.dwCursorPos.X, 2 
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR1
		push 1
		lea rax, str_eax_feature1
		push rax
			lea rax, outputData
			push rax
			push 4
			mov eax, cpuid_01[0*4]
			shr eax, 28
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 4 
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR2
		push 3
		lea rax, str_eax_feature2
		push rax
			lea rax, outputData
			push rax
			push 8
			mov eax, cpuid_01[0*4]
			shr eax, 20
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 14 
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR3
		push 1
		lea rax, str_eax_feature3
		push rax
			lea rax, outputData
			push rax
			push 4
			mov eax, cpuid_01[0*4]
			shr eax, 16
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 15 
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR4
		push 3
		lea rax, str_eax_feature4
		push rax
			lea rax, outputData
			push rax
			push 2
			mov eax, cpuid_01[0*4]
			shr eax, 14
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 6
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR5
		push 1
		lea rax, str_eax_feature5
		push rax
			lea rax, outputData
			push rax
			push 2
			mov eax, cpuid_01[0*4]
			shr eax, 12
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 13
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR6
		push 3
		lea rax, str_eax_feature6
		push rax
			lea rax, outputData
			push rax
			push 4
			mov eax, cpuid_01[0*4]
			shr eax, 8
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 9
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR7
		push 1
		lea rax, str_eax_feature7
		push rax
			lea rax, outputData
			push rax
			push 4
			mov eax, cpuid_01[0*4]
			shr eax, 4
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 5
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR8
		push 3
		lea rax, str_eax_feature8
		push rax
			lea rax, outputData
			push rax
			push 4
			mov eax, cpuid_01[0*4]
			shr eax, 0
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		lea rdx, csbiInfo								
		mov rcx, hStdOutput								
		call GetConsoleScreenBufferInfo					

		lea rax, str_NewLine							
		push rax										
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString
		lea rax, str_NewLine
		push rax
		call PrintString

		add csbiInfo.dwCursorPos.X, 2
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR1
		push 2
		lea rax, str_ebx_feature1
		push rax
			lea rax, outputData
			push rax
			push 8
			mov eax, cpuid_01[1*4]
			shr eax, 24
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 20
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR3
		push 2
		lea rax, str_ebx_feature2
		push rax
			lea rax, outputData
			push rax
			push 8
			mov eax, cpuid_01[1*4]
			shr eax, 16
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 20
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR5
		push 2
		lea rax, str_ebx_feature3
		push rax
			lea rax, outputData
			push rax
			push 8
			mov eax, cpuid_01[1*4]
			shr eax, 8
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		add csbiInfo.dwCursorPos.X, 20
		mov eax, csbiInfo.dwCursorPos
		push rax
		push COLOR7
		push 2
		lea rax, str_ebx_feature3
		push rax
			lea rax, outputData
			push rax
			push 8
			mov eax, cpuid_01[1*4]
			shr eax, 0
			push rax
			call NumToBin
		push rax
		call PrintBitLabel

		push 2												
		lea rax, table1_colors
		push rax 
		push 4
		lea rax, bit_label_ecx
		push rax
		push 40
			lea rax, outputData
			push rax
			push 32
			mov eax, cpuid_01[2*4]
			push rax
			call NumToBin
		push rax
		call PrintCoolTable

		lea rax, str_NewLine
		push rax
		call PrintString

		push 2
		lea rax, table2_colors
		push rax 
		push 4
		lea rax, bit_label_edx
		push rax
		push 40
			lea rax, outputData
			push rax
			push 32
			mov eax, cpuid_01[3*4]
			push rax
			call NumToBin
		push rax
		call PrintCoolTable
exit:
		call WaitAndTerminate							
		int 3											
	Start ENDP
end