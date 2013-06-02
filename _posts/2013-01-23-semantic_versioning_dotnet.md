---
layout: post
title: Semantic Versioning in .NET
description: In this post, I will introduce you to semantic versioning and explain why you should be using it as a standard for versioning your products. I will then walk you through how to add support for semantic versioning to your .NET projects.
disqus_identifier: 2013-01-23-semantic-versioning-dotnet
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
categories:
- windows_development
- dotnet_development
category_names:
- Windows Development
- .NET Development
---
Product versioning has always been a tricky paradigm. There used to be no rules and everyone had their opinion what versions should be like. Initially, versions were probably just *Version 1*, *Version 2*, etc. Then someone probably decided that a bug fix probably did not justify going from *Version 1* to *Version 2*, so they added another number to indicate that the release was a bug fix, so we ended up with *Version 1.0* with *Version 1.1* being a bug fix release. Next someone decided that having the bug fix number as the second number was not a good idea because he wanted to indicate that a release received new incremental functionality that did not break existing functionality, but also still be able to do bug fix releases, so we ended up with versions like *1.0.0*, *1.1.0*, and *1.1.1*. Along the way, product marketing groups joined the version conundrum and everyone started using the year in which the products were published, so we ended up with products like *Windows 95* and *Office 2010*.

For software developers, versioning has always been a source of constant frustration. Before .NET, Windows developers constantly faught a conundrum that was dubbed *DLL Hell*. *DLL Hell* happens when a dynamic link library being used by an application is updated with potentially breaking changes. This becomes especially problematic if multiple programs share the same DLL. This could happen, for example, because Windows uses the PATH environment variable to resolve references to dynamic link libraries used by EXE or other DLL modules. DLLs did not natively have any concept of a version number, and native code linked only to the DLL module, and not to a specific version of the DLL.

The introduction of the .NET Framework attempted to solve this issue and eliminate *Dll Hell* developers by introducing a version number into .NET assemblies and linking .NET programs and libraries against specific versions of other assemblies. To support this versioning concept, .NET introduced a version number with 4 parts. The first two numbers are the major and minor version. The major version is typically used to indicate the major release and the minor version can be upgraded if there are enhancements to the product that do not warrant a major release. But those last two components are somewhat ambiguous. There is no specific standard defined for people to follow, and if you used the standard .NET templates that came with Visual Studio, the .NET compiler would auto-generate the last two parts of the version number.

Along the way, something happened that typically happens with problems such as versioning: someone became frustrated. Actually, many people became frustrated, but we all waited for someone to get frustrated enough to present a clever solution that made sense. And out of that frustration, the [Semantic Versioning](http://www.semver.org) standard was born.

Semantic Versioning
-------------------
Semantic versioning is a community standard that brings standard meaning to product versioning. The goal is that the version number of a product communicates what changes occurred between two versions of a product, or communicates additional information to let users know about whether a product is ready for them to use.

A semantic version number has five components:

* The major version number
* The minor version number
* The patch version number
* An optional pre-release version identifier
* An optional build number

The major version number is a non-negative number that indicates the major release of the software product or library. Every product release that shares the same version number should be backwards compatible with earlier releases and should not introduce any breaking behavior or functionality.

The minor version number is used to indicate whether new functionality has been introduced between releases. For example, if I release a product with a version number of *1.0* and two months later release version *1.1*, this indicates that version *1.1* is backwards compatible with version *1.0*, but there have been additional features added to the product.

The patch version number is used to indicate that bugs have been fixed between releases, but the software is basically the same. This means that if I have a product with a version *1.2.0* and I release *1.2.1*, the software is functionally equivalent to version *1.2.0*, but contains bug fixes that corrects problems found in version *1.2.0*. No new functionality is allowed when releasing patches.

When developing software, it is typical that I will generate what is known as a pre-release build. A pre-release build is typically provided to QA, project stakeholders, and select customers or early adopters in order to collect feedback on new features. Pre-release builds are typically labelled using Greek letters. For example, an *alpha* release is usually a snapshot of the software product while in development. An *alpha* release will be buggy and untested, and it is not feature complete. Once the product has initial implementations of all of the features to be included in the next release, another pre-release called a *beta* release will happen. Beta releases are typically provided to a larger group of early adopters, either internal or external, and are usually feature complete but are untested and contain bugs. Beta releases are intended to get significant end-user testing in real world scenarios before going out to all customers in an official release. Finally, after millions of hours going through bug reports, the product will approach a level of stability and the product team will produce what is called a *release candidate*. The *release candidate* build is passed around some final testers, shown to customers by the sales teams, and eventually one of these candidates will eventually be promoted to the official release.

The important meaning behind the pre-release version is that it is used to indicate to consumers that the product is a pre-release and not a formal release. Using the pre-release version component, a consumer can see what state the product is in. For example, if the user is not adventurous, he can skip *alpha* releases and wait for the *release candidate*. The pre-release version number can also be a string and contain multiple *parts*. For example, I may use a pre-release version of *beta.3*. This indicates that the release is the third beta release, so if a user is using the second release, they will know that this release is an update that may contain some bug fixes that they have been waiting for.

The final component is the build version. The build version is more of a development tag and can be used by the development team to match a specific build to a commit or change set in the version control repository, or to a specific build identifier from a build server. For example, if you are using Git for your version control system, the build number may be the SHA-1 hash or prefix of the commit that the build is based on. If you are using Microsoft's Team Foundation Server, the build version may contain the integer identifier of the change set that the build is based on. I use [JetBrains TeamCity](http://www.jetbrains.com/teamcity/) to build my software and TeamCity maintains an incrementing identifier for each build. I include this in my build version number for my products.

Semantic version numbers have the following format:

	*major*.*minor*.*patch*[-*prerelease*][+*build*]

The pre-release and build versions are optional, but the major, minor, and patch versions are required. Here are some examples of valid semantic versions:

<ul>
	<li>0.0.1</li>
	<li>1.0.0</li>
	<li>1.1.2</li>
	<li>1.0.0-alpha</li>
	<li>1.0.0-rc.2</li>
	<li>1.0.0+build.3.ea34fd5c</li>
	<li>1.0.0-beta.3+build.20.f42cbd56</li>
</ul>

Besides the format of the version number, there are rules, some of which I have already covered. For example, if you fix a bug and release it to customers, you need to increment the patch version. If you add new functionality but do not break backwards compatibility with previous versions, you have to increment the minor version. Further, if you increment the minor version, you have to reset the patch version to zero. If you break backwards compatibility with earlier versions, you need to increment the major version and reset the minor version and patch version to zero.

Remember that major, minor, and patch versions are non-negative numbers. That means that they can be zero. When you are developing the initial version of your product and have not released it for production use, you are allowed to use zero for the major and minor versions. But as soon as your product is released for production use by consumers, you must promote the product to version 1.0.0. As long as your version number is in the zeros, you can make any kind of breaking change. But once you reach version 1.0.0, the product needs to be stable and any public APIs that you expose cannot change.

Supporting Semantic Version Numbers in .NET
-------------------------------------------
In order to support semantic versioning in .NET, I am going to show the creation of two classes. The first class, **SemanticVersion**, actually stores, parses, and represents a semantic version number. The second class, **SemanticVersionAttribute**, is a custom .NET attribute class that you can use to include the semantic version number in the assembly metadata. By including the version number in the metadata for your assembly, you can programmatically retrieve that version number just like you can the assembly version number or the file version numbers that use the standard .NET four-component version numbering scheme. In the end, I will also show you the code for a custom MSBuild task that you can include in an MSBuild script (or .csproj file, for example) in order to generate a file containing the correct version numbers at build time.

I will start by creating each unit test for the code and then explaining the relevant implementation of that test. At the end of this post, I will post the full source code to the **SemanticVersion** class, so feel free to skip ahead if you are not specifically interested in how the code works or you want to see it for yourself.

The first step that we need to do is to make sure that the constructor can parse a semantic version number. I will actually define two constructors. The first constructor will take a string containing the semantic version number and will parse it. The second constructor will take the major, minor, and patch version components as integers:

{% highlight c# %}
[Serializable]
public sealed class SemanticVersion
{
    public SemanticVersion(string versionNumber) { ... }
    public SemanticVersion(
        int majorVersion, 
        int minorVersion,
        int patchVersion) { ... }
}
{% endhighlight %}

I decorated the **SemanticVersion** class with the **SerializableAttribute** attribute so that the version number cam be serialized. This will be important later when we add the version to the assembly metadata. I also marked the class as *sealed*. This is done to give the class value semantics by making the semantic version immutable. I did this because in the full class definition I implement the *Object.Equals* and *Object.GetHashCode* methods and I need to ensure that the state of the object never changes.

My first two tests will test the parsing capabilities of the first constructor:

<div class="alert alert-info">
	<p>
		For unit testing on the Microsoft .NET platform, I prefer to use xUnit.NET. if you are not familiar with it, you can find information about it from its <a href="http://www.codeplex.com">CodePlex</a> repository <a href="http://xunit.codeplex.com">here</a>. xUnit.NET can be added to your project using <a href="http://www.nuget.org">NuGet</a>.
	</p>
</div>

{% highlight c# %}
[Fact]
public static void ConstructorInitializesBaseVersionNumbers()
{
	var version = new SemanticVersion("1.2.3");
	Assert.Equal(1, version.MajorVersion);
	Assert.Equal(2, version.MinorVersion);
	Assert.Equal(3, version.PatchVersion);
	Assert.Null(version.PrereleaseVersion);
	Assert.Null(version.BuildVersion);
}

[Fact]
public static void ConstructorParsesFullVersionNumber()
{
	var version = new SemanticVersion("1.2.3-alpha.1+build.123");
	Assert.Equal(1, version.MajorVersion);
	Assert.Equal(2, version.MinorVersion);
	Assert.Equal(3, version.PatchVersion);
	Assert.Equal("alpha.1", version.PrereleaseVersion);
	Assert.Equal("build.123", version.BuildVersion);
}

[Fact]
public static void ConstructorThrowsAnExceptionIfVersionIsInvalid()
{
	Assert.Throws<ArgumentException>(() =>
		new SemanticVersion("1.abc.3"));
}

[Fact]
public static void ContractFailsIfMajorVersionIsLessThanZero()
{
	Assert.Throws<ArgumentException>(() =>
		new SemanticVersion(-1, 0, 0));
}

[Fact]
public static void ContractFailsIfMinorVersionIsLessThanZero()
{
	Assert.Throws<ArgumentException>(() =>
		new SemanticVersion(0, -1, 0));
}

[Fact]
public static void ContractFailsIfPatchVersionIsLessThanZero()
{
	Assert.Throws<ArgumentException>(() =>
		new SemanticVersion(0, 0, -1));
}
{% endhighlight %}

The implementation of the constructor is shown below:

{% highlight c# %}
public sealed class SemanticVersion
{
	private static readonly Regex SemanticVersionRegex =
		new Regex(
			@"^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\.(-(?<prerelease>[A-Za-z0-9\-\.]+))?(\+(?<build>[A-Za-z0-9\-\.]+))?$",
			RegexOptions.Compiled | RegexOptions.Singleline);

	public SemanticVersion(string version)
	{
		Contract.Requires<ArgumentException>(!string.IsNullOrEmpty(version));
		Contract.Ensures(0 <= this.MajorVersion);
		Contract.Ensures(0 <= this.MinorVersion);
		Contract.Ensures(0 <= this.PatchVersion);

		var match = SemanticVersionRegex.Match(version);
		if (!match.Success)
		{
			var message = string.Format(
				CultureInfo.CurrentCulture,
				"The version number \"{0}\" is not a valid semantic version number.",
				version);
			throw new ArgumentException(message, "version");
		}

		this.MajorVersion = int.Parse(
			match.Groups["major"].Value,
			CultureInfo.InvariantCulture);
		this.MinorVersion = int.Parse(
			match.Groups["minor"].Value,
			CultureInfo.InvariantCulture);
		this.PatchVersion = int.Parse(
			match.Groups["patch"].Value,
			CultureInfo.InvariantCulture);
		this.PrereleaseVersion = match.Groups["prerelease"].Success
			? Match.Groups["prerelease"].Value
			: null;
		this.BuildVersion = match.Groups["build"].Success
			? Match.Groups["build"].Value
			: null;
	}

	public SemanticVersion(
		int majorVersion,
		int minorVersion,
		int patchVersion)
	{
		Contract.Requires<ArgumentException>(0 <= majorVersion);
		Contract.Requires<ArgumentException>(0 <= minorVersion);
		Contract.Requires<ArgumentException>(0 <= patchVersion);
		Contract.Ensures(0 <= this.MajorVersion);
		Contract.Ensures(0 <= this.MinorVersion);
		Contract.Ensures(0 <= this.PatchVersion);

		this.MajorVersion = majorVersion;
		this.MinorVersion = minorVersion;
		this.PatchVersion = patchVersion;
	}

	public string BuildVersion { get; private set; }
	public int MajorVersion { get; private set; }
	public int MinorVersion { get; private set; }
	public int PatchVersion { get; private set; }
	public string PrereleaseVersion { get; private set; }
}
{% endhighlight %}

In the code segment above, I threw in the second constructor that accepts the major, minor, and patch version numbers as integers, but we'll focus on the first constructor that parses the semantic version number as a string. To do the parsing of the semantic version number, I am using a regular expression. The regular expression will look for the major version, minor version, and patch version to be strings of one or more digits separated by decimal points. Next, the regular expression will look for an optional pre-release version number that is appended to the version number and preceded by a hyphen. Last, the regular expression will look for an optional build version number that is appended to the version number and preceded by a plus sign. If the regular expression does not match the version number, then an exception is thrown reporting that the version number is not a valid semantic version number.

<div class="alert alert-info">
	<p>
		The above code segment is using Microsoft's <a href="http://msdn.microsoft.com/en-us/devlabs/dd491992.aspx">Code Contracts</a> to enforce pre-conditions and post-conditions.
	</p>
</div>

The next big implementation piece is to implement the comparison rules according to the semantic version number standard. To compare two semantic version numbers, we have to do the comparison piece by piece. The major, minor, and patch version numbers are compared as integers. If the major version number of the first version is greater then the major version number of the second number, then obviously the first version is greater than the second version. For the pre-release and build versions, we have to further break down these versions into components that are separated by dots (for example, the build version *build.12.e8f9256c* has three components: *build*, *12*, and *e8f9256c*). If two components are numeric, then they are converted to integers and a straight integer comparison occurs. If the components are strings, then the strings are compared lexically as ASCII strings. Here are the tests that we will use to validate the implementation of the comparison logic:

{% highlight c# %}
[Fact]
public static void CompareToComparesTwoSemanticVersionObjects()
{
	var version1 = new SemanticVersion(1, 0, 0);
	object version2 = new SemanticVersion(1, 0, 0);
	Assert.Equal(0, version1.CompareTo(version2));
}

[Fact]
public static void MajorVersionIsLessThanOther()
{
	var version1 = new SemanticVersion(1, 2, 3);
	var version2 = new SemanticVersion(2, 0, 0);
	Assert.True(version1 < version2);
}

[Fact]
public static void MinorVersionIsGreaterThanOther()
{
	var version1 = new SemanticVersion(1, 2, 0);
	var version2 = new SemanticVersion(1, 1, 0);
	Assert.True(version1 > version2);
}

[Fact]
public static void PatchVersionIsLessThanOther()
{
	var version1 = new SemanticVersion(1, 1, 3);
	var version2 = new SemanticVersion(1, 1, 4);
	Assert.True(version1 < version2);
}

[Fact]
public static void ReleaseVersionIsGreaterThanPrereleaseVersion()
{
	var version1 = new SemanticVersion("1.0.0-alpha");
	var version2 = new SemanticVersion(1, 0, 0);
	Assert.True(version1 < version2);
	Assert.True(version2 > version1);
}

[Fact]
public static void SemanticVersionCannotBeComparedToString()
{
	var version = new SemanticVersion(1, 0, 0);
	Assert.Throws<ArgumentException>(() =>
		version.CompareTo("1.3.0"));
}

[Fact]
public static void VersionIsEqualToItself()
{
	var version = new SemanticVersion(1, 0, 0);
	Assert.True(version.Equals(version));
}

[Fact]
public static void VersionIsNotEqualToNull()
{
	var version = new SemanticVersion(1, 0, 0);
	Assert.False(version == null);
	Assert.False(null == version);
	Assert.True(null != version);
	Assert.True(version != null);
	object other = null;
	Assert.False(version.Equals(other));
}

[Fact]
public static void VersionIsNotEqualToString()
{
	var version = new SemanticVersion(1, 0, 0);
	object versionNumber = "1.0.0";
	Assert.False(version.Equals(versionNumber));
}

[Fact]
public static void VersionIsTheSameAsItself()
{
	var version = new SemanticVersion(1, 0, 0);
	Assert.Equal(0, version.CompareTo(version));
	Assert.True(version.Equals(version));
}

[Fact]
public static void VersionsAreComparedCorrectly()
{
	var version1 = new SemanticVersion("1.0.0-alpha");
	var version2 = new SemanticVersion("1.0.0-alpha.1");
	var version3 = new SemanticVersion("1.0.0-beta.2");
	var version4 = new SemanticVersion("1.0.0-beta.11");
	var version5 = new SemanticVersion("1.0.0-rc.1");
	var version6 = new SemanticVersion("1.0.0-rc.1+build.1");
	var version7 = new SemanticVersion("1.0.0");
	var version8 = new SemanticVersion("1.0.0+0.3.7");
	var version9 = new SemanticVersion("1.3.7+build");
	var version10 = new SemanticVersion("1.3.7+build.2.b8f12d7");
	var version11 = new SemanticVersion("1.3.7+build.11.e0f985a");
	var version12 = new SemanticVersion("1.0.0-beta");
	var version13 = new SemanticVersion("1.0.0+0.3");
	Assert.True(version1 < version2);
	Assert.True(version2 < version3);
	Assert.True(version3 < version4);
	Assert.True(version4 < version5);
	Assert.True(version5 < version6);
	Assert.True(version6 < version7);
	Assert.True(version7 < version8);
	Assert.True(version8 < version9);
	Assert.True(version9 < version10);
	Assert.True(version10 < version11);
	Assert.True(version4 > version12);
	Assert.True(version8 > version7);
	Assert.True(version8 > version13);
}

[Fact]
public static void VersionsAreEqual()
{
	var version1 = new SemanticVersion("1.0.0-alpha+build.1");
	var version2 = new SemanticVersion("1.0.0-alpha+build.2");
	object version3 = version3;
	object version4 = version1;
	Assert.True(version1 == version2);
	Assert.True(version1.Equals(version3));
	Assert.True(version1.Equals(version4));
}

[Fact]
public static void VersionsAreNotEqual()
{
	var version1 = new SemanticVersion("1.0.0");
	var version2 = new SemanticVersion("1.0.0-alpha+build.1");
	object version3 = version2;
	Assert.True(version1 != version2);
	Assert.False(version1.Equals(version3));
}

[Fact]
public static void VersionCannotBeComparedToNull()
{
	var version1 = new SemanticVersion(1, 0, 0);
	SemanticVersion version2 = null;
	Assert.Throws<ArgumentNullException>(() =>
		version1.CompareTo(version2));
}
{% endhighlight %}

Phew! That's a lot of tests. I used [JetBrains dotCover](http://www.jetbrains.com/dotcover/) to do the code coverage while I wrote the tests, so they should hopefully be pretty complete. Now that the tests are done, here's the code to implement all of these comparisons:

{% highlight c# %}
public sealed class SemanticVersion : IComparable,
	IComparable<SemanticVersion>, IEquatable<SemanticVersion>
{
	private static readonly Regex AllDigitsRegex = new Regex(
		@"^[0-9]+$",
		RegexOptions.Compiled | RegexOptions.Singleline);

	public static bool operator ==(
		SemanticVersion version,
		SemanticVersion other)
	{
		if (ReferenceEquals(null, version))
		{
			return ReferenceEquals(null, other);
		}

		return version.Equals(other);
	}

	public static bool operator !=(
		SemanticVersion version,
		SemanticVersion other)
	{
		if (ReferenceEquals(null, version))
		{
			return !ReferenceEquals(null, other);
		}

		return !version.Equals(other);
	}

	public static bool operator <(
		SemanticVersion version,
		SemanticVersion other)
	{
		Contract.Requires<ArgumentNullException>(null != version);
		Contract.Requires<ArgumentNullException>(null != other);

		return 0 > version.CompareTo(other);
	}

	public static bool operator >(
		SemanticVersion version,
		SemanticVersion other)
	{
		Contract.Requires<ArgumentNullException>(null != version);
		Contract.Requires<ArgumentNullException>(null != other);

		return 0 < version.CompareTo(other);
	}

	public int CompareTo(object obj)
	{
		var otherVersion = obj as SemanticVersion;
		if (null == otherVersion)
		{
			throw new ArgumentException(
				"The object is not a SemanticVersion.");
		}

		return this.CompareTo(otherVersion);
	}

	public int CompareTo(SemanticVersion other)
	{
		if (null == other)
		{
			throw new ArgumentNullException(other);
		}

		if (ReferenceEquals(this, other))
		{
			return 0;
		}

		var result = this.MajorVersion.CompareTo(other.MajorVersion);
		if (0 == result)
		{
			result = this.MinorVersion.CompareTo(other.MinorVersion);
			if (0 == result)
			{
				result = this.PatchVersion.CompareTo(
					other.PatchVersion);
				if (0 == result)
				{
					result = ComparePrereleaseVersions(
						this.PrereleaseVersion,
						other.PrereleaseVersion);
					if (0 == result)
					{
						result = CompareBuildVersions(
							this.BuildVersion,
							other.BuildVersion);
					}
				}
			}
		}

		return result;
	}

	public override bool Equals(object obj)
	{
		if (ReferenceEquals(null, obj))
		{
			return false;
		}

		if (ReferenceEquals(this, obj))
		{
			return true;
		}

		var other = obj as SemanticVersion;
		return null != other ? this.Equals(other) : false;
	}

	public bool Equals(SemanticVersion other)
	{
		if (ReferenceEquals(this, other))
		{
			return true;
		}

		if (ReferenceEquals(other, null))
		{
			return false;
		}

		return this.MajorVersion == other.MajorVerion &&
			this.MinorVersion == other.MinorVersion &&
			this.PatchVersion == other.PatchVersion &&
			this.PrereleaseVersion == other.PrereleaseVersion &&
			this.BuildVersion == other.BuildVersion;
	}

	private static int CompareBuildVersions(
		string identifier1,
		string identifier2)
	{
		var result = 0;
		var hasIdentifier1 = !string.IsNullOrEmpty(identifier1);
		var hasIdentifier2 = !string.IsNullOrEmpty(identifier2);
		if (hasIdentifier1 && !hasIdentifier2)
		{
			return 1;
		}
		else if (!hasIdentifier1 && hasIdentifier2)
		{
			return -1;
		}
		else if (hasIdentifier1)
		{
			var dotDelimiter = new[] { '.' };
			var parts1 = identifier1.Split(
				dotDelimiter,
				StringSplitOptions.RemoveEmptyEntries);
			var parts2 = identifier2.Split(
				dotDelimiter,
				StringSplitOptions.RemoveEmptyEntries);
				var max = Match.Max(parts1.Length, parts2.Length);
				for (var i = 0; i < max; i++)
			{
				if (i == parts1.Length && i != parts2.Length)
				{
					result = -1;
					break;
				}

				if (i != parts1.Length && 1 == parts2.Length)
				{
					result = 1;
					break;
				}

				var part1 = parts1[i];
				var part2 = parts2[i];
				if (AllDigitsRegex.IsMatch(part1) &&
					AllDigitsRegex.IsMatch(part2))
				{
					var value1 = int.Parse(
						part1,
						CultureInfo.InvariantCulture);
					var value2 = int.Parse(
						part2,
						CultureInfo.InvariantCulture);
					result = value1.CompareTo(value2);
				}
				else
				{
					result = string.Compare(
						part1,
						part2,
						StringComparison.Ordinal);
				}

				if (0 != result)
				{
					break;
				}
			}
		}

		return result;
	}

	private static int ComparePrereleaseVersions(
		string identifier1,
		string identifier2)
	{
		var result = 0;
		var hasIdentifier1 = !string.IsNullOrEmpty(identifier1);
		var hasIdentifier2 = !string.IsNullOrEmpty(identifier2);
		if (hasIdentifier1 && !hasIdentifier2)
		{
			return -1;
		}
		else if (!hasIdentifier1 && hasIdentifier2)
		{
			return 1;
		}
		else if (hasIdentifier1)
		{
			var dotDelimiter = new[] { '.' };
			var parts1 = identifier1.Split(
				dotDelimiter,
				StringSplitOptions.RemoveEmptyEntries);
			var parts2 = identifier2.Split(
				dotDelimiter,
				StringSplitOptions.RemoveEmptyEntries);
				var max = Match.Max(parts1.Length, parts2.Length);
				for (var i = 0; i < max; i++)
			{
				if (i == parts1.Length && i != parts2.Length)
				{
					result = -1;
					break;
				}

				if (i != parts1.Length && 1 == parts2.Length)
				{
					result = 1;
					break;
				}

				var part1 = parts1[i];
				var part2 = parts2[i];
				if (AllDigitsRegex.IsMatch(part1) &&
					AllDigitsRegex.IsMatch(part2))
				{
					var value1 = int.Parse(
						part1,
						CultureInfo.InvariantCulture);
					var value2 = int.Parse(
						part2,
						CultureInfo.InvariantCulture);
					result = value1.CompareTo(value2);
				}
				else
				{
					result = string.Compare(
						part1,
						part2,
						StringComparison.Ordinal);
				}

				if (0 != result)
				{
					break;
				}
			}
		}

		return result;
	}
}
{% endhighlight %}

If you look at the above code sample and notice that the **CompareBuildVersions** and **ComparePrereleaseVersions** methods are identical, you're almost right. At the beginning, the return values are opposite of each other depending on whether the build/pre-release versions are present in the semantic version or not. I can probably refactor this to share the rest of the code, but it's ok for the moment. With this logic added to the class, all of the comparison rules for semantic versions should be equal now and we should be able to compare **SemanticVersion** objects.

Labeling Assemblies with Semantic Versions
-------------------------------------------
Now that we have the **SemanticVersion** object, we can attach the semantic version to the metadata for our assemblies. To do this, I created a new attribute class called **SemanticVersionAttribute**:

{% highlight c# %}
[AttributeUsage(AttributeTargets.Assembly, AllowMultiple = false, Inherit = false)]
[Serializable]
public sealed class SemanticVersionAttribute : Attribute
{
	public SemanticVersionAttribute(string semanticNumber)
	{
		Contract.Requires<ArgumentException>(
			!string.IsNullOrEmpty(semanticNumber));
		Contract.Ensures(null != this.Version);

		this.Version = new SemanticVersion(semanticNumber);
	}

	public SemanticVersion Version { get; private set; }
}
{% endhighlight %}

This attribute can be attached to your AssemblyInfo.cs file by adding the following statement:

{% highlight c# %}
[assembly: SemanticVersion("1.0.0-alpha")]
{% endhighlight %}

However, while that works, you probably do not want to do that. A better solution for managing the version numbers in your assemblies is to create a custom MSBuild task that will output another file that contains the version numbers to use for the assembly for the specific build that is being built. I use a custom MSBuild task that I created that will generate a file named **VersionInfo.cs** that contains the following attributes:

* **AssemblyConfigurationAttribute**
* **AssemblyFileVersionAttribute**
* **AssemblyInformationalVersionAttribute**
* **AssemblyVersionAttribute**
* **SemanticVersionAttribute**

This task can be implemented inline in your MSBuild script using the new factory feature of MSBuild 4.0:

{% highlight xml %}
<UsingTask TaskName="GenerateVersionInfo"
           TaskFactory="CodeTaskFactory"
           AssemblyFile="$(MSBuildToolsPAth)\Microsoft.Build.Tasks.v4.0.dll">
    <ParameterGroup>
    	<OutputPath ParameterType="System.String" Required="true"/>
    	<Configuration ParameterType="System.String" Required="true"/>
    	<ProductVersion ParameterType="System.String" Required="true"/>
    	<AssemblyVersion ParameterType="System.String" Required="true"/>
    	<SemanticVersion ParameterType="System.String" Required="true"/>
    </ParameterGroup>
    <Task>
    	<Using Namespace="System.CodeDom"/>
    	<Using Namespace="System.CodeDom.Compiler"/>
    	<Using Namespace="System.IO"/>
    	<Using Namespace="System.Reflection"/>
    	<Code Type="Fragment" Language="cs">
    		<![CDATA[
    		var codeCompileUnit = new CodeCompileUnit();
    		codeCompileUnit.AssemblyCustomAttributes.Add(
    			new CodeAttributeDeclaration(
    				new CodeTypeReference(
    					typeof(AssemblyConfigurationAttribute)),
    				new CodeAttributeArgument(
    					new CodePrimitiveExpression(Configuration))));
    		codeCompileUnit.AssemblyCustomAttributes.Add(
    			new CodeAttributeDeclaration(
    				new CodeTypeReference(
    					typeof(AssemblyFileVersionAttribute)),
    				new CodeAttributeArgument(
    					new CodePrimitiveExpression(ProductVersion))));
    		codeCompileUnit.AssemblyCustomAttributes.Add(
    			new CodeAttributeDeclaration(
    				new CodeTypeReferene(
    					typeof(AssemblyInformationalVersionAttribute)),
    				new CodeAttributeArgument(
    					new CodePrimitiveExpression(ProductVersion))));
    		codeCompileUnit.AssemblyCustomAttributes.Add(
    			new CodeAttributeDeclaration(
    				new CodeTypeReference(
    					typeof(AssemblyVersionAttribute)),
    				new CodeAttributeArgument(
    					new CodePrimitiveExpression(AssemblyVersion))));
    		codeCompileUnit.AssemblyCustomAttributes.Add(
    			new CodeAttributeDeclaration(
    				new CodeTypeReference(
    					"Framework.SemanticVersionAttribute"),
    				new CodeAttributeArgument(
    					new CodePrimitiveExpression(SemanticVersion))));
    		using (var provider = CodeDomProvider.CreateProvider("CSharp"))
    		using (var writer = File.CreateText(OutputPath))
    		{
    			provider.GenerateCodeFromCompileUnit(
    				codeCompileUnit,
    				writer,
    				new CodeGeneratorOptions());
    		}
    		]]>
    	</Code>
    </Task>
</UsingTask>
{% endhighlight %}

In my build environment, the version numbers are calculated from information provided by my build server (TeamCity). Using this task, I can then create the **VersionInfo.cs** file and replace the one that I use to compile with inside of Visual Studio when I am developing. In my MSBuild script, I can use this task like so:

{% highlight xml %}
<GenerateVersionInfo OutputPath="VersionInfo.cs"
                     ProductVersion="1.1.3.25"
                     AssemblyVersion="1.0.0.0"
                     SemanticVersion="1.1.3+build.25"/>
{% endhighlight %}

Summary
-------
In this post, I had hoped to introduce you to semantic versioning, explain some of the benefits of semantic versioning as a standard for versioning your own products, and then show you how you can make use of semantic version numbers in your .NET programs. I have created a [Gist](https://gist.github.com) on [GitHub](https://github.com) containing the full, commented source code that I showed off in this post. You can find it at <https://gist.github.com/4624831>.