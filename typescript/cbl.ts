declare const Promise:any;
declare const cbl: any;
declare const _:any;

export class JnCBLAdapter {

    dbName: string;
    syncUrl: string;
    model: any;
    options: any;

    constructor() {
        this.dbName = '';
        this.syncUrl = '';
        this.model = null;
        this.options = null;
    }

    allDocs() {
        return cbl.allDocs$([this.dbName]);
    }

    /**gets a single document based on _id*/
    getDoc(docId: string, isLocal: boolean = false): any {
        if (!_.isString(docId)) {
            return Promise.try(() => {
                throw Error('doc Id is not a string');
            });
        } else {
            return cbl.get([this.dbName, docId, isLocal ? "true" : "false"])
                .catch((error) => _.merge(new Error('getDoc failed in ' + this.dbName), error));
        }
    }

    putAttachment(docId: string, attachmentFileName: string, attachmentName: string, mime: string, dirName: string) {
        return cbl.putAttachment([this.dbName, docId, attachmentFileName, attachmentName, mime, dirName]);
    }

    /** puts a single document in the database*/
    putDoc(doc, isLocal: boolean = false) {
        if (!_.isObject(doc)) {
            return Promise.try(() => {
                throw Error('doc to be written is not an object');
            });
        }
        else {
            return cbl.upsert([this.dbName, doc._id, JSON.stringify(doc), isLocal ? 'local' : 'normal'])
                .then(()=>doc);
        }
    }

    /**deletes a single doc from the database.*/
    deleteDoc(doc) {

    }

    init(dataBaseName: string, syncURL: string) {
        this.dbName = dataBaseName;
        this.syncUrl = syncURL;
        return cbl.initDb([dataBaseName]);
    }

    compact() {
        return cbl.compact([this.dbName]);
    }

    getDocRev(id:string) {
        return cbl.getDocRev([this.dbName, id])
    }

    getChangesDatabase$() {
        return cbl.changesDatabase$([this.dbName]);

    }

    getChangesReplication$() {
        return cbl.changesReplication$([this.dbName]);
    }

    getLocalDbInfo() {
        return cbl.info([this.dbName])
            .catch((error) => _.merge(new Error('getLocalDbInfo failure in ' + this.dbName), error));
    }

    sync(user: string, pass: string) {
        return cbl.sync([this.dbName, this.syncUrl, user, pass]);
    }

    reset() {
        const dyingDb = this.dbName;
        this.dbName = '';
        this.syncUrl = '';
        cbl.reset();
        return 'db log off complete for db: ' + dyingDb;
    }
}