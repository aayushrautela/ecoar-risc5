.eqv	stack_size 		512
.eqv	stdin_size		128
.data
# typedef void (*opcode)(const char*) opcode_impl
# typedef struct _command {
# 	opcode_impl impl;	// implementation function pointer
#   const char* name;	// mnemonic (opcode name literal)
#	const int numop;	// number of expected operands
# } command;
# command commands[] = 
.align	2
commands:
# {
		# .word {void* impl, char* name, int numop}
		.word	impl_add, name_add, 2
		.word	impl_sub, name_sub, 2
		.word	impl_mul, name_mul, 2
		.word	impl_div, name_div, 2
		.word	impl_dup, name_dup, 1
		.word	impl_pop, name_pop, 1
		.word	impl_exit, name_exit, 1
		.word	0, 0, 0
# };
.align	2
# int stack[stack_size / sizeof(int)];
stack:	.space	stack_size
# const char* buffer[buffer_size]
.align	0
stdin:	.space	stdin_size
# const char* mnemonics[] = 
.align	0
mnemonics:
# {
		name_add:		.asciz	"add"
		name_sub:		.asciz	"sub"
		name_mul:		.asciz	"mul"
		name_div:		.asciz	"div"
		name_dup:		.asciz	"dup"
		name_pop:		.asciz	"pop"
		name_push:		.asciz	"push"
		name_exit:		.asciz	"exit"
# };
# const char* errors[] = 
.align	0
errors:
# {
	err_unknown_opcode:	.asciz	"unknown instruction\n"
	err_stack_empty:	.asciz	"insufficient stack\n"
	err_stack_overflow:	.asciz	"stack overflow\n"
	err_stdin_empty:	.asciz	"stdin is empty\n"
	err_stdin_overflow:	.asciz	"stdin overflow\n"
	err_missing_oparg:	.asciz	"missing operand\n"
	err_unexpected_chr:	.asciz	"unexpected char: "
	err_atoi_too_many:	.asciz	"too many operands\n"
# };
.text
main:
	# register variable assignment
	.eqv	stack_ptr	s0	# current vm stack pointer
	.eqv	stack_lim	s1	# current vm stack limit (max address)
	.eqv	stdin_ptr	s2	# current vm terminal pointer
	.eqv	stdin_lim	s3	# current vm terminal limit (max address)
	.eqv	curr_impl	s4	# current opcode implementation
	.eqv	curr_name	s5	# current opcode name literal
	.eqv	curr_args	s6	# current opcode operands
	.eqv	curr_iter	s7	# opcode lookup iterator
	.eqv	atoi_break	s8	# ptr to the end of mnemonic name
	.eqv	atoi_order	s9	# order (power of 10) for atoi
	.eqv	atoi_value	s10	# value (result) for atoi
	.eqv	atoi_steps	s11	# length of number in digits
	# stack operations defined as macros
.macro	stack_push(%reg)
	addi	stack_ptr, stack_ptr, -4
	sw		%reg, (stack_ptr)
.end_macro
.macro	stack_peek(%reg)
	lw		%reg, (stack_ptr)
.end_macro
.macro	stack_pop(%reg)
	lw		%reg, (stack_ptr)
	addi	stack_ptr, stack_ptr, +4
.end_macro
	# memset(stack, 0, stack_size);
	la		a0, stack
	mv		a1, zero
	li		a2, stack_size
	call	memset
	# initialize stack
	la		stack_ptr, stack
	li		stack_lim, stack_size
	add		stack_lim, stack_lim, stack_ptr
	mv		stack_ptr, stack_lim
	# initialize stdin
	la		stdin_ptr, stdin
	li		stdin_lim, stdin_size
	add		stdin_lim, stdin_lim, stdin_ptr
	# begin repl loop
repl_loop:
	# memset(stdin, 0, stdin_size);
	la		a0, stdin
	mv		a1, zero
	li		a2, stdin_size
	call	memset
	# print preamble
	li		a7, 11
	li		a0, '>'
	ecall
	li		a0, ' '
	ecall
	# request input
	li		a7, 8
	mv		a0, stdin_ptr
	sub		a1, stdin_lim, stdin_ptr
	ecall
	# parse mnemonic
	la		curr_iter, commands
parse_loop:
	lw		curr_impl, 0(curr_iter)
	lw		curr_name, 4(curr_iter)
	lw		curr_args, 8(curr_iter)
	beqz	curr_impl, parse_failed
	stack_push(stdin_ptr)	# just to save, to undo whatever tf i did
match_loop:
	lbu		t0, (curr_name)
	beqz	t0, match_found
	lbu		t1, (stdin_ptr)
	bne		t0, t1, match_fail
	addi	curr_name, curr_name, 1
	addi	stdin_ptr, stdin_ptr, 1
	j		match_loop
match_fail:
	stack_pop(stdin_ptr)
	addi	curr_iter, curr_iter, 12
	j		parse_loop
	# parse and push integer operands
match_found:
	stack_pop(zero)
	mv		atoi_break, stdin_ptr
	li		t6, '\n'
seek_end_line:
	lbu		t0, (stdin_ptr)
	beqz	t0, found_end_line
	beq		t0, t6, found_end_line
	addi	stdin_ptr, stdin_ptr, 1
	j		seek_end_line
found_end_line:
	ble		stdin_ptr, atoi_break, parse_success
	addi	stdin_ptr, stdin_ptr, -1
operands_loop:
	li		atoi_order, 1
	mv		atoi_value, zero
	mv		atoi_steps, zero
	li		t6, '-'
	li		t5, '9'
	li		t4, '0'
	li		t3, ' '
	li		t2, 10
atoi_loop:
	lbu		t0, (stdin_ptr)
	beq		t0, t6, atoi_negative
	beq		t0, t3, atoi_positive
	blt		t0, t4, atoi_unexpected_chr
	bgt		t0, t5, atoi_unexpected_chr
	sub		t0, t0, t4
	mul		t0, t0, atoi_order
	add		atoi_value, atoi_value, t0
	mul		atoi_order, atoi_order, t2
	addi	atoi_steps, atoi_steps, 1
	addi	stdin_ptr, stdin_ptr, -1
	ble		stdin_ptr, atoi_break, atoi_positive
	j		atoi_loop
atoi_negative:
	beqz	atoi_steps, atoi_unexpected_chr
	li		t0, -1
	mul		atoi_value, atoi_value, t0
	addi	stdin_ptr, stdin_ptr, -1
	addi	curr_args, curr_args, -1
	bltz	curr_args, atoi_too_many
	stack_push(atoi_value)
	ble		stdin_ptr, atoi_break, parse_success
	j		operands_loop
atoi_positive:
	beqz	atoi_steps, atoi_unexpected_chr
	addi	stdin_ptr, stdin_ptr, -1
	addi	curr_args, curr_args, -1
	bltz	curr_args, atoi_too_many
	stack_push(atoi_value)
	ble		stdin_ptr, atoi_break, parse_success
	j		operands_loop
atoi_unexpected_chr:
	li		a7, 4
	la		a0, err_unexpected_chr
	ecall
	li		a7, 11
	mv		a0, t0
	ecall
	li		a7, 11
	li		a0, '\n'
	ecall
	j		repl_loop
atoi_too_many:
	li		a7, 4
	la		a0, err_atoi_too_many
	ecall
	j		repl_loop
parse_failed:
	li		a7, 4
	la		a0, err_unknown_opcode
	ecall
	j		repl_loop
parse_success:
	# assert num_operands
	beqz	curr_args, assert_stack_size
	sub		t0, stack_lim, stack_ptr
	srli	t0, t0, 2
	bge		t0, curr_args, assert_stack_size
	li		a7, 4
	la		a0, err_stack_empty
	ecall
	j		repl_loop
assert_stack_size:
	# jump to opcode implementation
	jr		curr_impl
#####################

# add [%word], [%word]
impl_add:
	stack_pop(t0)
	stack_pop(t1)
	add		t0, t0, t1
	stack_push(t0)
	j		repl_loop
# sub [%word], [%word]
impl_sub:
	stack_pop(t0)
	stack_pop(t1)
	sub		t0, t0, t1
	stack_push(t0)
	j		repl_loop
# mul [%word], [%word]
impl_mul:
	stack_pop(t0)
	stack_pop(t1)
	mul		t0, t0, t1
	stack_push(t0)
	j		repl_loop
# div [%word], [%word]
impl_div:
	stack_pop(t0)
	stack_pop(t1)
	div		t0, t0, t1
	stack_push(t0)
	j		repl_loop
# dup
impl_dup:
	stack_peek(t0)
	stack_push(t0)
	j		repl_loop
# pop
impl_pop:
	stack_pop(a0)
	li		a7, 1
	ecall
	li		a7, 11
	li		a0, '\n'
	ecall
	j		repl_loop
# exit [%code]
impl_exit:
	stack_pop(a0)
	li		a7, 93
	ecall
	
# void memset(void* ptr, char value, size_t size)
memset:
	add		t6, a0, a2				# t6 := ptr + size
memset_loop:
	sb		a1, (a0)				# *ptr = value
	addi	a0, a0, 1				# ++ptr
	blt		a0, t6, memset_loop		# if (ptr < t6) goto memset_loop
	ret
