using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace Gearbound.Core
{
    /// <summary>
    /// Minimal strict JSON reader for shared game data. Objects become
    /// <c>Dictionary&lt;string, object&gt;</c>, arrays <c>List&lt;object&gt;</c>, integers <c>long</c>,
    /// other numbers <c>double</c>. Kept dependency-free so Gearbound.Core stays engine-independent.
    /// </summary>
    public static class SharedJson
    {
        public static object Parse(string text)
        {
            if (text == null) throw new ArgumentNullException(nameof(text));
            var reader = new Reader(text);
            var value = reader.ReadValue();
            reader.SkipWhitespace();
            if (!reader.AtEnd) throw reader.Error("Unexpected trailing content");
            return value;
        }

        public static Dictionary<string, object> Obj(object value, string where) =>
            value as Dictionary<string, object> ?? throw new FormatException($"{where}: expected an object.");

        public static List<object> Arr(Dictionary<string, object> obj, string key) =>
            obj.TryGetValue(key, out var value) && value is List<object> list ? list : throw new FormatException($"'{key}' must be an array.");

        public static int Int(Dictionary<string, object> obj, string key)
        {
            if (!obj.TryGetValue(key, out var value) || !(value is long number)) throw new FormatException($"'{key}' must be an integer.");
            if (number < int.MinValue || number > int.MaxValue) throw new FormatException($"'{key}' is out of range.");
            return (int)number;
        }

        public static long Long(Dictionary<string, object> obj, string key) =>
            obj.TryGetValue(key, out var value) && value is long number ? number : throw new FormatException($"'{key}' must be an integer.");

        public static string Str(Dictionary<string, object> obj, string key) =>
            obj.TryGetValue(key, out var value) && value is string text ? text : throw new FormatException($"'{key}' must be a string.");

        public static bool Bool(Dictionary<string, object> obj, string key, bool fallback = false) =>
            obj.TryGetValue(key, out var value) && value is bool flag ? flag : fallback;

        /// <summary>
        /// Writes a value built from dictionaries (keys in insertion order), lists, strings, booleans, null and integers
        /// as compact JSON. Used for checkpoints that Dart must be able to read back.
        /// </summary>
        public static string Write(object value)
        {
            var b = new StringBuilder();
            WriteValue(b, value);
            return b.ToString();
        }

        private static void WriteValue(StringBuilder b, object value)
        {
            if (value == null) { b.Append("null"); return; }
            if (value is string s) { WriteString(b, s); return; }
            if (value is bool flag) { b.Append(flag ? "true" : "false"); return; }
            if (value is int || value is long || value is uint)
            {
                b.Append(Convert.ToInt64(value, CultureInfo.InvariantCulture).ToString(CultureInfo.InvariantCulture));
                return;
            }
            if (value is IDictionary<string, object> map)
            {
                b.Append('{');
                var first = true;
                foreach (var pair in map)
                {
                    if (!first) b.Append(',');
                    first = false;
                    WriteString(b, pair.Key);
                    b.Append(':');
                    WriteValue(b, pair.Value);
                }
                b.Append('}');
                return;
            }
            if (value is System.Collections.IEnumerable items)
            {
                b.Append('[');
                var first = true;
                foreach (var item in items)
                {
                    if (!first) b.Append(',');
                    first = false;
                    WriteValue(b, item);
                }
                b.Append(']');
                return;
            }
            throw new FormatException("Cannot write " + value.GetType().Name + " as shared JSON.");
        }

        private static void WriteString(StringBuilder b, string s)
        {
            b.Append('"');
            foreach (var c in s)
            {
                if (c == '"') b.Append("\\\"");
                else if (c == '\\') b.Append("\\\\");
                else if (c < ' ') b.Append("\\u").Append(((int)c).ToString("x4", CultureInfo.InvariantCulture));
                else b.Append(c);
            }
            b.Append('"');
        }

        private sealed class Reader
        {
            private readonly string text;
            private int index;
            public Reader(string text) => this.text = text;
            public bool AtEnd => index >= text.Length;
            public FormatException Error(string message) => new FormatException($"{message} at offset {index}.");

            public void SkipWhitespace()
            {
                while (!AtEnd && (text[index] == ' ' || text[index] == '\t' || text[index] == '\n' || text[index] == '\r')) index++;
            }

            public object ReadValue()
            {
                SkipWhitespace();
                if (AtEnd) throw Error("Unexpected end of JSON");
                switch (text[index])
                {
                    case '{': return ReadObject();
                    case '[': return ReadArray();
                    case '"': return ReadString();
                    case 't': Expect("true"); return true;
                    case 'f': Expect("false"); return false;
                    case 'n': Expect("null"); return null;
                    default: return ReadNumber();
                }
            }

            private void Expect(string literal)
            {
                if (string.CompareOrdinal(text, index, literal, 0, literal.Length) != 0) throw Error($"Expected '{literal}'");
                index += literal.Length;
            }

            private Dictionary<string, object> ReadObject()
            {
                var result = new Dictionary<string, object>(StringComparer.Ordinal);
                index++;
                SkipWhitespace();
                if (!AtEnd && text[index] == '}') { index++; return result; }
                while (true)
                {
                    SkipWhitespace();
                    if (AtEnd || text[index] != '"') throw Error("Expected object key");
                    var key = ReadString();
                    SkipWhitespace();
                    if (AtEnd || text[index] != ':') throw Error("Expected ':'");
                    index++;
                    if (result.ContainsKey(key)) throw Error($"Duplicate key '{key}'");
                    result[key] = ReadValue();
                    SkipWhitespace();
                    if (AtEnd) throw Error("Unterminated object");
                    if (text[index] == ',') { index++; continue; }
                    if (text[index] == '}') { index++; return result; }
                    throw Error("Expected ',' or '}'");
                }
            }

            private List<object> ReadArray()
            {
                var result = new List<object>();
                index++;
                SkipWhitespace();
                if (!AtEnd && text[index] == ']') { index++; return result; }
                while (true)
                {
                    result.Add(ReadValue());
                    SkipWhitespace();
                    if (AtEnd) throw Error("Unterminated array");
                    if (text[index] == ',') { index++; continue; }
                    if (text[index] == ']') { index++; return result; }
                    throw Error("Expected ',' or ']'");
                }
            }

            private string ReadString()
            {
                var builder = new StringBuilder();
                index++;
                while (true)
                {
                    if (AtEnd) throw Error("Unterminated string");
                    var c = text[index++];
                    if (c == '"') return builder.ToString();
                    if (c != '\\') { builder.Append(c); continue; }
                    if (AtEnd) throw Error("Unterminated escape");
                    var e = text[index++];
                    switch (e)
                    {
                        case '"': builder.Append('"'); break;
                        case '\\': builder.Append('\\'); break;
                        case '/': builder.Append('/'); break;
                        case 'b': builder.Append('\b'); break;
                        case 'f': builder.Append('\f'); break;
                        case 'n': builder.Append('\n'); break;
                        case 'r': builder.Append('\r'); break;
                        case 't': builder.Append('\t'); break;
                        case 'u':
                            if (index + 4 > text.Length) throw Error("Bad unicode escape");
                            builder.Append((char)int.Parse(text.Substring(index, 4), NumberStyles.HexNumber, CultureInfo.InvariantCulture));
                            index += 4;
                            break;
                        default: throw Error("Unknown escape");
                    }
                }
            }

            private object ReadNumber()
            {
                var start = index;
                if (text[index] == '-') index++;
                while (!AtEnd && char.IsDigit(text[index])) index++;
                var isInteger = true;
                if (!AtEnd && text[index] == '.') { isInteger = false; index++; while (!AtEnd && char.IsDigit(text[index])) index++; }
                if (!AtEnd && (text[index] == 'e' || text[index] == 'E'))
                {
                    isInteger = false;
                    index++;
                    if (!AtEnd && (text[index] == '+' || text[index] == '-')) index++;
                    while (!AtEnd && char.IsDigit(text[index])) index++;
                }
                var token = text.Substring(start, index - start);
                if (token.Length == 0 || token == "-") throw Error("Invalid value");
                if (isInteger && long.TryParse(token, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var whole)) return whole;
                return double.Parse(token, NumberStyles.Float, CultureInfo.InvariantCulture);
            }
        }
    }
}
