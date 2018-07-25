package com.couchbase.cblite.phonegap;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import com.couchbase.lite.ArrayFunction;
import com.couchbase.lite.Authenticator;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseChange;
import com.couchbase.lite.DatabaseChangeListener;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class CBLite extends CordovaPlugin {

    final static int MAX_THREADS = 3;
    private static HashMap<String, Replicator> mReplicators = null;
    private static HashMap<String, DatabaseChangeListener> changeListeners = null;
    //    private static HashMap<String, Replication.ChangeListener> replicationListeners = null;
    private static ArrayList<CallbackContext> callbacks = null;
    private static int runnerCount = 0;
    //    private static Manager dbmgr = null;
    private static HashMap<String, Database> dbs = null;
    private Context mContext;

    public CBLite() {
        super();
    }

    static private String replicationResponse(String dbName, String type, String Message) {
        return "{\"db\":\"" + dbName + "\",\"type\":\"" + type + "\",\"message\":\"" + Message + "\"}";
    }

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        try {
            mContext = this.cordova.getActivity();
            dbs = new HashMap<String, Database>();

            //                    mapper.getFactory().configure(JsonGenerator.Feature.ESCAPE_NON_ASCII, true);
            //                    View.setCompiler(new JavaScriptViewCompiler());
            //                    Database.setFilterCompiler(new JavaScriptReplicationFilterCompiler());
            //                    dbmgr = startCBLite(this.cordova.getActivity());
            //
            mReplicators = new HashMap<String, Replicator>();
            changeListeners = new HashMap<String, DatabaseChangeListener>();
            //                    replicationListeners = new HashMap<String, Replication.ChangeListener>();
            callbacks = new ArrayList<CallbackContext>();
        } catch (final Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callback) {

        //UTIL
        if (action.equals("changesDatabase")) {
            changesDatabase(args, callback);
        } else if (action.equals("changesReplication")) {
            changesReplication(args, callback);
        } else if (action.equals("compact")) {
            compact(args, callback);
        } else if (action.equals("info")) {
            info(args, callback);
        } else if (action.equals("initDb")) {
            initDb(args, callback);
        } else if (action.equals("lastSequence")) {
            lastSequence(args, callback);
        } else if (action.equals("replicateFrom")) {
            replicateFrom(args, callback);
        } else if (action.equals("replicateTo")) {
            replicateTo(args, callback);
        } else if (action.equals("reset")) {
            reset(args, callback);
        } else if (action.equals("stopReplication")) {
            stopReplication(args, callback);
        } else if (action.equals("sync")) {
            sync(args, callback);
        } else if (action.equals("resetCallbacks")) {
            resetCallbacks(args, callback);
        }

        //READ
        else if (action.equals("allDocs")) {
            allDocs(args, callback);
        } else if (action.equals("get")) {
            get(args, callback);
        } else if (action.equals("getDocRev")) {
            getDocRev(args, callback);
        } else if (action.equals("query")) {
            query(args, callback);
        }

        //WRITE
        else if (action.equals("putAttachment")) {
            putAttachment(args, callback);
        } else if (action.equals("upsert")) {
            upsert(args, callback);
        } else if (action.equals("attachmentCount")) {
            attachmentCount(args, callback);
        } else if (action.equals("uploadLogs")) {
            uploadLogs(args, callback);
        }

        return true;
    }

    @Override
    public void onPause(boolean multitasking) {
        System.out.println("CBLite.onPause() called");
    }

    @Override
    public void onResume(boolean multitasking) {
        System.out.println("CBLite.onResume() called");
    }

    @Override
    public void onReset() {
        //cancel change listeners
        //        for (String dbName : changeListeners.keySet()) {
        //            for (Database.ChangeListener listener : changeListeners.values()) {
        //                dbs.get(dbName).removeChangeListener(listener);
        //            }
        //        }
        //
        //        for (String dbName : replicationListeners.keySet()) {
        //            for (Replication.ChangeListener listener : replicationListeners.values()) {
        //                try {
        //                    mReplicators.get(dbName + "_push").removeChangeListener(listener);
        //                } catch (Exception e) {
        //                }
        //                try {
        //                    mReplicators.get(dbName + "_pull").removeChangeListener(listener);
        //                } catch (Exception e) {
        //                }
        //            }
        //        }
        //
        //        //cancel mReplicators
        //        for (Replication replication : mReplicators.values()) {
        //            replication.stop();
        //        }
        //
        //        //cancel callbacks
        //        for (CallbackContext context : callbacks) {
        //            PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        //            result.setKeepCallback(false);
        //            context.sendPluginResult(result);
        //        }
        //
        //        dbs.clear();
        //        changeListeners.clear();
        //        replicationListeners.clear();
        //        mReplicators.clear();
        //        callbacks.clear();
        //        runnerCount = 0;
    }

    private void resetCallbacks(final JSONArray args, final CallbackContext callback) {
        //cancel callbacks
        //        for (CallbackContext context : callbacks) {
        //            PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        //            result.setKeepCallback(false);
        //            context.sendPluginResult(result);
        //        }
        //        callbacks.clear();
        //        callback.success("reset callbacks");
    }

    private void uploadLogs(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String url = args.getString(1);
        //                    final String processId = Integer.toString(android.os.Process.myPid());
        //                    StringBuilder builder = new StringBuilder();
        //
        //                    BufferedReader bufferedReader;
        //
        //                    try {
        //                        String[] command = new String[]{"logcat", "-d", "-v", "threadtime"};
        //                        Process process = Runtime.getRuntime().exec(command);
        //                        bufferedReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        //                        String line;
        //                        while ((line = bufferedReader.readLine()) != null) {
        //                            if (line.contains(processId)) builder.append(line + "\n");
        //                        }
        //                        String fileName = dbName + "-" + System.currentTimeMillis() / 1000L;
        //                        final OkHttpClient client = new OkHttpClient();
        //
        //                        RequestBody requestBody = new MultipartBody.Builder()
        //                                .setType(MultipartBody.FORM)
        //                                .addPart(
        //                                        Headers.of("Content-Disposition", "form-data; name=\"files\";filename=\"android-logcat-" + fileName + "\""),
        //                                        RequestBody.create(null, builder.toString()))
        //                                .build();
        //
        //                        Request request = new Request.Builder()
        //                                .header("Content-Type", "application/json")
        //                                .url(url)
        //                                .post(requestBody)
        //                                .build();
        //
        //                        Response response = client.newCall(request).execute();
        //                        if (!response.isSuccessful())  {
        //                            RaygunClient.send(new IOException("Unexpected code " + response.code()));
        //                        }
        //                        bufferedReader.close();
        //                        process.destroy();
        //                        response.close();
        //                        callback.success(response.message());
        //                    } catch (Exception ex) {
        //                        RaygunClient.send(ex);
        //                        callback.success(ex.getMessage());
        //                    }
        //                } catch (final Exception e) {
        //                    RaygunClient.send(e);
        //                    callback.success(e.getMessage());
        //                }
        //            }
        //        });
    }

    //    static private void handleSyncStateEvent(final Replication.ChangeEvent event, final String dbName, final String type, final CallbackContext callback) {
    ////        String response;
    ////        Replication.ReplicationStatus status = event.getStatus();
    ////        if (event.getError() != null) {
    ////            Throwable lastError = event.getError();
    ////            if (lastError instanceof RemoteRequestResponseException) {
    ////                RemoteRequestResponseException exception = (RemoteRequestResponseException) lastError;
    ////                if (exception.getCode() == 401)
    ////                    response = replicationResponse(dbName, "error_" + type, "REPLICATION_UNAUTHORIZED");
    ////                else if (exception.getCode() == 404)
    ////                    response = replicationResponse(dbName, "error_" + type, "REPLICATION_NOT_FOUND");
    ////                else if (exception.getCode() > 0)
    ////                    response = replicationResponse(dbName, "error_" + type, "REPLICATION_ERROR_CODE_" + exception.getCode());
    ////                else
    ////                    response = replicationResponse(dbName, "error_" + type, "REPLICATION_UNKNOWN_ERROR");
    ////            } else response = replicationResponse(dbName, type, status.toString());
    ////        } else response = replicationResponse(dbName, type, status.toString());
    ////
    ////        PluginResult result = new PluginResult(PluginResult.Status.OK, response);
    ////        result.setKeepCallback(true);
    ////        callback.sendPluginResult(result);
    //    }

    private void attachmentCount(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    Document doc = dbs.get(dbName).getDocument(args.getString(1));
        //                    Revision rev = doc.getCurrentRevision();
        //                    List<Attachment> allAttachments = rev.getAttachments();
        //                    callback.success(allAttachments.size());
        //                } catch (final Exception e) {
        //                    RaygunClient.send(e);
        //                    callback.success(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void changesDatabase(final JSONArray args, final CallbackContext callback) {
        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callback.sendPluginResult(result);

        callbacks.add(callback);

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    final String dbName = args.getString(0);

                    if (dbs.get(dbName) != null) {
                        changeListeners.put(dbName, new DatabaseChangeListener() {
                            @Override
                            public void changed(DatabaseChange event) {
                                List<String> ids = event.getDocumentIDs();

                                JSONArray ja = new JSONArray(ids);

                                PluginResult result = new PluginResult(PluginResult.Status.OK, ja.toString());
                                result.setKeepCallback(true);
                                callback.sendPluginResult(result);
                            }
                        });

                        dbs.get(dbName).addChangeListener(changeListeners.get(dbName));
                    }
                } catch (final Exception e) {
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private void changesReplication(final JSONArray args, final CallbackContext callback) {
        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callback.sendPluginResult(result);

        callbacks.add(callback);

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    final String dbName = args.getString(0);

                    Replicator replicator = mReplicators.get(dbName);
                    replicator.addChangeListener(new ReplicatorChangeListener() {
                        @Override
                        public void changed(ReplicatorChange change) {
                            Replicator.ActivityLevel activityLevel = change.getStatus().getActivityLevel();

                            HashMap<String, String> response = new HashMap<String, String>();
                            response.put("db", dbName);
                            response.put("type", "PUSH_AND_PULL");
                            response.put("total", Long.toString(change.getStatus().getProgress().getTotal()));
                            response.put("completed", Long.toString(change.getStatus().getProgress().getCompleted()));

                            switch (activityLevel) {
                                case BUSY:
                                    Log.d(CBLite.class.getSimpleName(),
                                            "Replication BUSY"
                                                    + "\nReplication " + change.getStatus().getProgress().getCompleted()
                                                    + " of " + change.getStatus().getProgress().getTotal());

                                    response.put("message", "REPLICATION_ACTIVE");

                                    break;

                                case IDLE:
                                    Log.d(CBLite.class.getSimpleName(), "Replication IDLE");

                                    response.put("message", "REPLICATION_IDLE");

                                    break;

                                case STOPPED:
                                    Log.d(CBLite.class.getSimpleName(), "Replication STOPPED");

                                    response.put("message", "REPLICATION_STOPPED");

                                    break;

                                case OFFLINE:
                                    Log.d(CBLite.class.getSimpleName(), "Replication OFFLINE");

                                    response.put("message", "REPLICATION_OFFLINE");

                                    break;

                                case CONNECTING:
                                    Log.d(CBLite.class.getSimpleName(), "Replication CONNECTING");

                                    response.put("message", "REPLICATION_CONNECTING");

                                    break;
                            }

                            JSONObject responseJo = new JSONObject(response);

                            PluginResult result = new PluginResult(PluginResult.Status.OK, responseJo.toString());
                            result.setKeepCallback(true);
                            callback.sendPluginResult(result);
                        }
                    });
                //    replicator.stop();
                    replicator.start();
                } catch (final Exception e) {
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private void compact(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    dbs.get(dbName).compact();
        //                    callback.success("attachment saved!");
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void info(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    callback.success(dbs.get(dbName).getDocumentCount());
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void initDb(final JSONArray args, final CallbackContext callback) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String dbName = args.getString(0);

                    DatabaseConfiguration config = new DatabaseConfiguration(mContext);
                    Database database = new Database(dbName, config);

                    dbs.put(dbName, database);

                    callback.success("CBL db init success");
                } catch (final Exception e) {
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private void lastSequence(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    callback.success((int) dbs.get(dbName).getLastSequenceNumber());
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void replicateFrom(JSONArray args, CallbackContext callback) {
    }

    private void replicateTo(JSONArray args, CallbackContext callback) {
    }

    private void reset(JSONArray args, CallbackContext callback) {
        this.onReset();
    }

    private void stopReplication(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    Database db = dbs.get(dbName);
        //                    if (db != null) {
        //                        for (Replication replication : db.getAllReplications()) replication.stop();
        //                        callback.success("true");
        //                    } else callback.error("false");
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void sync(final JSONArray args, final CallbackContext callback) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String dbName = args.getString(0);
                    URI uri = new URI(args.getString(1));
                    String user = args.getString(2);
                    String pass = args.getString(3);

                    Authenticator authenticator = new BasicAuthenticator(user, pass);

                    Endpoint endpoint = new URLEndpoint(uri);
                    ReplicatorConfiguration config = new ReplicatorConfiguration(dbs.get(dbName), endpoint);
                    config.setAuthenticator(authenticator)
                            .setContinuous(true)
                            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
                    Replicator replicator = new Replicator(config);

                    mReplicators.put(dbName, replicator);

//                    replicator.start();

                    callback.success("true");
                } catch (Exception e) {
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private void allDocs(final JSONArray args, final CallbackContext callback) {
        PluginResult firstResult = new PluginResult(PluginResult.Status.NO_RESULT);
        firstResult.setKeepCallback(true);
        callback.sendPluginResult(firstResult);
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    final String dbName = args.getString(0);

                    Query query = QueryBuilder.select(SelectResult.all())
                            .from(DataSource.database(dbs.get(dbName)));
                    ResultSet results = query.execute();
                    final List<Result> resultsList = results.allResults();

                    ArrayList<Object> idList = new ArrayList<Object>();

                    final ArrayList<String> responseBuffer = new ArrayList<String>();


                    for (Result row : resultsList) {
                        Dictionary all = row.getDictionary(dbName);

                        try {
                            JSONObject obj = new JSONObject(all.toMap());

                            responseBuffer.add(obj.toString());
                        } catch (Exception e) {
                            PluginResult result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
                            result.setKeepCallback(false);
                            callback.sendPluginResult(result);
                        }
                    }

                    PluginResult result = new PluginResult(PluginResult.Status.OK,
                            "[" + TextUtils.join(",", responseBuffer) + "]");
                    result.setKeepCallback(true);
                    callback.sendPluginResult(result);
                } catch (Exception e) {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
                    result.setKeepCallback(false);
                    callback.sendPluginResult(result);
                }
            }
        });
    }

    public void query(final JSONArray args, final CallbackContext callback) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String dbName = args.getString(0);
                    String field = args.getString(1);
                    String searchQuery = args.getString(2);
                    String isLocal = args.getString(3);

                    if (isLocal.equals("true")) {
                        // TODO:
                    } else {
                        JSONObject searchQueryJo = new JSONObject(searchQuery);
                        String group = "";
                        JSONArray searchJa = null;

                        if (searchQueryJo != null) {
                            if (searchQueryJo.has("group")) {
                                group = searchQueryJo.getString("group");
                            }

                            if (searchQueryJo.has("search")) {
                                searchJa = searchQueryJo.getJSONArray("search");
                            }

                            Expression whereExpression = null;

                            if (searchJa != null) {
                                for (int i = 0; i < searchJa.length(); ++i) {
                                    JSONObject jo = searchJa.getJSONObject(i);

                                    if (jo.has("field") && jo.has("method") && jo.has("where")) {
                                        Expression exp = buildSearchExpression(jo.getString("field"),
                                                jo.getString("where"),
                                                jo.getString("method"),
                                                (i == 0 ? "" : group));

                                        if (exp != null) {
                                            if (whereExpression == null) {
                                                whereExpression = exp;
                                            } else {
                                                if (group.equalsIgnoreCase("AND")) {
                                                    whereExpression = whereExpression.and(exp);
                                                } else if (group.equalsIgnoreCase("OR")) {
                                                    whereExpression = whereExpression.or(exp);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if (whereExpression == null) {
                                whereExpression = Expression.all();
                            }

                            Query query = QueryBuilder.select(SelectResult.all())
                                    .from(DataSource.database(dbs.get(dbName)))
                                    .where(whereExpression);
                            ResultSet results = query.execute();
                            final List<Result> resultsList = results.allResults();

                            ArrayList<Object> idList = new ArrayList<Object>();

                            final ArrayList<String> responseBuffer = new ArrayList<String>();

                            for (Result row : resultsList) {
                                Dictionary all = row.getDictionary(dbName);

                                try {
                                    JSONObject obj = new JSONObject(all.toMap());

                                    responseBuffer.add(obj.toString());
                                } catch (Exception e) {
                                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
                                    result.setKeepCallback(false);
                                    callback.sendPluginResult(result);
                                }
                            }

                            PluginResult result = new PluginResult(PluginResult.Status.OK,
                                    "[" + TextUtils.join(",", responseBuffer) + "]");
                            result.setKeepCallback(true);
                            callback.sendPluginResult(result);
                        }
                    }
                } catch (final Exception e) {
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private Expression buildSearchExpression(String field, String where, String method, String concatenator) {
        Expression whereExpression = null;

        if (!TextUtils.isEmpty(field) && !TextUtils.isEmpty(where)
                && !TextUtils.isEmpty(method) && concatenator != null) {

            if (method.equalsIgnoreCase("equalTo")) {
                whereExpression = Expression.property(field).equalTo(Expression.string(where));
            } else if (method.equalsIgnoreCase("contains")) {
                whereExpression = ArrayFunction.contains(Expression.property(field), Expression.string(where));
            }
        }

        return whereExpression;
    }

    private void get(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String id = args.getString(1);
        //                    String isLocal = args.getString(2);
        //
        //                    if (isLocal.equals("true")) {
        //                        Map<String, Object> localDoc = dbs.get(dbName).getExistingLocalDocument(id);
        //                        if (localDoc != null) {
        //                            callback.success(mapper.writeValueAsString(localDoc));
        //                        } else callback.error("null");
        //                    } else {
        //                        Document doc = dbs.get(dbName).getExistingDocument(id);
        //                        if (doc != null) {
        //                            String jsonString = mapper.writeValueAsString(doc.getProperties());
        //                            callback.success(jsonString);
        //                        } else callback.error("null");
        //                    }
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    private void getDocRev(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String id = args.getString(1);
        //
        //                    Document doc = dbs.get(dbName).getExistingDocument(id);
        //                    if (doc != null) {
        //                        callback.success(doc.getCurrentRevisionId());
        //                    } else callback.error("null");
        //
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }

    //PLUGIN BOILER PLATE

    //    private Manager startCBLite(Context context) {
    //        try {
    //            Manager.enableLogging(Log.TAG_SYNC, Log.VERBOSE);
    //            Manager.enableLogging(Log.TAG_REMOTE_REQUEST, Log.VERBOSE);
    //            Manager.enableLogging(Log.TAG_CHANGE_TRACKER, Log.VERBOSE);
    //            Manager.enableLogging(Log.TAG_BLOB_STORE, Log.VERBOSE);
    //            Manager.enableLogging(Log.TAG_DATABASE, Log.VERBOSE);
    //            dbmgr = new Manager(new AndroidContext(context), Manager.DEFAULT_OPTIONS);
    //        } catch (IOException e) {
    //            throw new RuntimeException(e);
    //        }
    //        return dbmgr;
    //    }

    private void putAttachment(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String filePath = cordova.getActivity().getApplicationContext().getFilesDir() + "/" + args.getString(5) + "/" + args.getString(2);
        //                    FileInputStream stream = new FileInputStream(filePath);
        //                    Document doc = dbs.get(dbName).getDocument(args.getString(1));
        //                    UnsavedRevision newRev = doc.getCurrentRevision().createRevision();
        //                    newRev.setAttachment(args.getString(3), args.getString(4), stream);
        //                    newRev.save();
        //                    callback.success("sucess");
        //                } catch (final Exception e) {
        //                    callback.error("putAttachment failure");
        //                }
        //            }
        //        });
    }

    private void upsert(final JSONArray args, final CallbackContext callback) {
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String id = args.getString(1);
        //                    String jsonString = args.getString(2);
        //                    String isLocal = args.getString(3);
        //
        //                    if (isLocal.equals("local")) {
        //                        Map<String, Object> mapDoc = mapper.readValue(jsonString, new TypeReference<Map<String, Object>>() {
        //                        });
        //                        dbs.get(dbName).putLocalDocument(id, mapDoc);
        //                        callback.success("local upsert successful");
        //                    } else {
        //                        Document doc = dbs.get(dbName).getExistingDocument(id);
        //                        //if doc does not exist
        //                        if (doc == null) {
        //                            final Map<String, Object> mapDoc = mapper.readValue(jsonString, new TypeReference<Map<String, Object>>() {
        //                            });
        //                            Document document = dbs.get(dbName).getDocument(id);
        //                            document.putProperties(mapDoc);
        //                            callback.success("upsert successful");
        //                        }
        //                        //doc exists, force update
        //                        else {
        //                            final Map<String, Object> mapDoc = mapper.readValue(jsonString, new TypeReference<Map<String, Object>>() {
        //                            });
        //                            doc.update(new Document.DocumentUpdater() {
        //                                @Override
        //                                public boolean update(UnsavedRevision newRevision) {
        //                                    newRevision.setUserProperties(mapDoc);
        //                                    callback.success("upsert successful");
        //                                    return true;
        //                                }
        //                            });
        //                        }
        //                    }
        //                } catch (final Exception e) {
        //                    callback.error(e.getMessage());
        //                }
        //            }
        //        });
    }
}
