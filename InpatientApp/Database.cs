using System;
using System.Data;
using System.Data.SqlClient;

namespace InpatientApp
{
    /// <summary>
    /// Central place for the SQL Server connection. Every screen uses this class,
    /// so the connection string is written only once.
    /// </summary>
    public static class Database
    {
        // Change ServerName if your server has a different name
        // (e.g. "localhost" or "localhost\\SQLEXPRESS").
        public const string ServerName = @".\SQLEXPRESS";
        public const string DatabaseName = "InpatientDB";

        public static readonly string ConnectionString =
            "Data Source=" + ServerName +
            ";Initial Catalog=" + DatabaseName +
            ";Integrated Security=True" +      // Windows Authentication
            ";TrustServerCertificate=True;";   // avoids the certificate error

        public static SqlConnection GetConnection()
        {
            return new SqlConnection(ConnectionString);
        }

        /// <summary>Tries to open the connection. Returns true if it works.</summary>
        public static bool TestConnection(out string message)
        {
            try
            {
                using (SqlConnection con = GetConnection())
                {
                    con.Open();
                    message = "Connected to " + DatabaseName + " on " + ServerName;
                    return true;
                }
            }
            catch (Exception ex)
            {
                message = "Cannot connect to the database: " + ex.Message;
                return false;
            }
        }

        // ---------- Helper methods for the other screens (always use parameters) ----------

        /// <summary>Runs a SELECT and returns the rows (use for grids and combo boxes).</summary>
        public static DataTable GetTable(string sql, params SqlParameter[] parameters)
        {
            using (SqlConnection con = GetConnection())
            using (SqlCommand cmd = new SqlCommand(sql, con))
            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
            {
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }

        /// <summary>Runs INSERT / UPDATE / DELETE and returns the number of affected rows.</summary>
        public static int Execute(string sql, params SqlParameter[] parameters)
        {
            using (SqlConnection con = GetConnection())
            using (SqlCommand cmd = new SqlCommand(sql, con))
            {
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                con.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        /// <summary>Runs a query that returns a single value (e.g. COUNT or SCOPE_IDENTITY).</summary>
        public static object Scalar(string sql, params SqlParameter[] parameters)
        {
            using (SqlConnection con = GetConnection())
            using (SqlCommand cmd = new SqlCommand(sql, con))
            {
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                con.Open();
                return cmd.ExecuteScalar();
            }
        }
    }
}
