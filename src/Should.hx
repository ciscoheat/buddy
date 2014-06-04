package ;

class ShouldInt
{
	static public function should(d : Int)
	{
		return new Be<Int>(d);
	}
}

class ShouldString
{
	static public function should(d : String)
	{
		return new Be<String>(d);
	}
}

class Be<T>
{
	var input : T;

	public function new(input : T)
	{
		this.input = input;
	}

	public function be(v : T)
	{
		if (input != v) throw 'Fail: "$v" != "$input"';
	}
}
